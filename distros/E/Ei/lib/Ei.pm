package Ei;

use strict;
use warnings;

use File::Basename qw(dirname);
use File::Spec;

use vars qw($VERSION);

$VERSION = '0.07';

sub new {
    my $cls = shift;
    unshift @_, 'file' if @_ % 2;
    my $self = bless {
        @_,
    }, $cls;
    my $conf = $self->{config} = $self->_read_config($self->{config_file});
    my $root = $self->{root} ||= glob($conf->{files}{root});
    my $file = $self->{file};
    if (!defined $file) {
        ($file) = glob($conf->{files}{main});
        die "no file from which to read inventory" if !defined $file;
    }
    $self->{defaults} = $conf->{items}{defaults} || {};
    $self->{file} = File::Spec->rel2abs($file, $root) if $file !~ m{^/};
    $self->{interactive} ||= -t STDIN;
    return $self;
}

sub file { $_[0]->{file} }

sub find {
    my $self = shift;
    my @items = $self->items;
}

sub items {
    my ($self) = @_;
    return @{ $self->{'items'} ||= [ $self->_read_items($self->file) ] };
}

sub item {
    my ($self, $id) = @_;
    my $items = $self->{'items_by_id'} ||= { map { $_->{'#'} => $_ } $self->items };
    return $items->{$id};
}

sub locations {
    my ($self) = @_;
    return $self->{config}{locations} ||= {};
}

sub reload {
    my $self = shift;
    if (@_) {
        die "not yet implemented";
    }
    else {
        my $file = $self->file;
        $self->{'items'} = [ $self->_read_items($file) ];
        delete $self->{'items_by_id'};
    }
    return $self;
}

sub merge {
    my ($self, $obj, $k, $op, $v) = @_;
    my $d = $obj;
    my $r = ref $obj;
    while ($k =~ /[\[\].]/) {
        if ($k =~ s/^([^\[.]+)\.//) {
            $d = $d->{$1} ||= {};
        }
        else {
            die "Huh?";
        }
        $r = ref $d;
    }
    if ($op eq '+') {
        my $vprev = $d->{$k};
        my $r = defined $vprev ? ref $vprev : '';
        if ($r eq '') {
            $d->{$k} = [ defined $vprev ? ($vprev) : (), $v ];
        }
        elsif ($r eq 'ARRAY') {
            push @$vprev, $v;
        }
        else {
            die "attempt to add to non-list: $vprev <= $k $op $v";
        }
    }
    elsif ($op eq '=') {
        $d->{$k} = $v;
    }
}

sub _read_file {
    my ($self, $f, %defaults) = @_;
    open my $fh, '<', $f or die "Can't open $f $!";
    my %hash;
    while (<$fh>) {
        next if /^\s*(?:#.*)?$/;
        if (/^!include\s+(\S+)$/) {
            my $source = File::Spec->rel2abs($1, dirname($f));
            my @files = -d $source ? grep { -f } glob("$source/*.ei") : (glob($source));
            foreach my $f (@files) {
                %hash = ( %hash, %{ $self->_read_file($f, %defaults) } );
            }
        }
        elsif (s/^\s*(\S+)\s+//) {
            my $key = $1;
            my $val = $self->_read_value($_, $fh, $f, $.);
            $hash{$key} = $val;
        }
        else {
            die qq{Expected a value at file $f line $.};
        }
    }
    return \%hash;
}

sub _read_items {
    my ($self, $f, %defaults) = @_;
    open my $fh, '<', $f or die "Can't open $f $!";
    my @items;
    while (<$fh>) {
        next if /^\s*(?:#.*)?$/;
        chomp;
        if (/^!include\s+(\S+)$/) {
            my $source = File::Spec->rel2abs($1, dirname($f));
            my @files = -d $source ? grep { -f } glob("$source/*.ei") : (glob($source));
            foreach my $f (@files) {
                push @items, $self->_read_items($f, %defaults);
            }
        }
        elsif (/^!default\s+(\S+)\s+(.*)$/) {
            $defaults{$1} = $2;
        }
        elsif (s/^\s*(?:"(\\.|[^\\"])+"|(\S+))\s+(?=\{)//) {
            my $key = defined $1 ? unquote($1) : $2;
            my $isdef = $key eq '*';
            my $line = $.;
            my %item = (
                %{ $self->{'defaults'} },
                %defaults,
                %{ $self->_read_value($_, $fh, $f, $.) },
            );
            if ($isdef) {
                %defaults = ( %defaults, %item );
            }
            else {
                $item{'#'} = $key;
                $item{'/'} = $f;
                $item{'.'} = $line;
                push @items, \%item;
            }
        }
#       elsif (s/^\s*(\S+)\s+//) {
#           my $key = $1;
#           my $val = $self->_read_value($_, $fh, $f, $.);
#           die "Value $val is not a hash" if ref($val) ne 'HASH';
#           $val->{'#'} = $key;
#           push @items, $val;
#       }
        else {
            die qq{Expected hash element at line $. of $f};
        }
    }
    return @items;
}

sub _read_value {
    my $self = shift;
    local $_ = shift;
    my ($fh, $f, $l) = @_;
    return [ map { trim($_) } split /,/, $1 ] if /^\s*\[(.+)\]\s*$/;
    return { map { my ($k, $v) = split /\s+/; (trim($k), trim($v)) } split /,/, $1 } if /^\s*\{(.+)\}\s*$/;
    return unquote($1) if /^\s*"(.+)"\s*$/;
    return $self->_read_array($fh, $f, $l)  if /^\s*\[\s*$/;
    return $self->_read_hash($fh, $f, $l)   if /^\s*\{\s*$/;
    return $self->_read_string($fh, $f, $l) if /^\s*\"\s*$/;
    #die if !/^(.*)$/;
    return trim($_);
}

sub _read_array {
    my ($self, $fh, $f, $l) = @_;
    my (@array, $ok);
    my $i = 0;
    while (<$fh>) {
        next if /^\s*(?:#.*)?$/;
        $ok = 1, last if /^\s*\]\s*$/;
        $array[$i++] = $self->_read_value($_, $fh, $f, $.);
    }
    die "Unterminated array at line $l of $f" if !$ok;
    return \@array;
}

sub _read_hash {
    my ($self, $fh, $f, $l) = @_;
    my (%hash, $ok);
    while (<$fh>) {
        next if /^\s*(?:#.*)?$/;
        $ok = 1, last if /^\s*\}\s*$/;
        s/^\s*(?:"(\\.|[^\\"])+"|(\S+))(?=\s)//
            or die "Not a hash element: $_";
        my $key = defined $1 ? unquote($1) : $2;
        my $val = $self->_read_value($_, $fh, $f, $.);
        $hash{$key} = $val;
    }
    die "Unterminated hash at line $l of $f" if !$ok;
    return \%hash;
}

sub _read_string {
    my ($self, $fh, $f, $l) = @_;
    my (@array, $ok);
    my $str = '';
    while (<$fh>) {
        $ok = 1, last if /^\s*\"\s*$/;
        $str .= $_;
    }
    die "Unterminated string at line $l of $f" if !$ok;
    chomp $str;
    return $str;
}

sub _read_config {
    my ($self, $f) = @_;
    my $hash = $self->_read_file($f);
    return $hash;
    open my $fh, '<', $f or die "Can't open $f $!";
    while (<$fh>) {
        next if /^\s*(?:#.*)?$/;
        s/^config\s+// or die "Bad config file $f: $_";
        return $self->_read_hash($fh, $f, $.);
    }
}

sub write {
    my ($self, $fh, @items) = @_;
    foreach my $item (@items) {
        my $id = delete $item->{'#'} // delete $item->{id};
        my $str = $self->serialize($item);
        print $fh $id, ' ', $str, "\n\n";
    }
}

sub prototypes {
    my ($self) = @_;
    return keys %{ $self->{config}{prototypes} };
}

sub prototype {
    my ($self, $p) = @_;
    my $proto = $self->{config}{prototypes}{$p} or return;
    if (my $inherit = $proto->{inherit}) {
        %{ $proto->{properties} } = (
            %{ $self->prototype($inherit)->{properties} },
            %{ $proto->{properties} },
        );
    }
    return $proto;
}

sub serialize {
    my ($self, $item) = @_;
    return join "\n", _serialize(0, $item);
}

sub _serialize {
    my ($level, $val) = @_;
    my $r = ref $val;
    if ($r eq 'HASH') {
        return _serialize_hash($level+1, $val);
    }
    elsif ($r eq 'ARRAY') {
        return _serialize_array($level+1, $val);
    }
    else {
        die if $r ne '';
        return $val if $val !~ /^\s/ && $val !~ /^[\\\[\]\{\}]/;
        $val =~ s/([\\\[\]\{\}])/\\$1/g;
        return $val;
    }
}

sub _serialize_hash {
    my ($level, $hash) = @_;
    my @out = '{';
    my $indstr = '    ' x ($level-0);
    foreach my $k (sort keys %$hash) {
        my $v = $hash->{$k};
        my @val = _serialize($level, $v);
        push @out, sprintf('%s%s %s', $indstr, $k, shift @val);
        push @out, @val;
    }
    $indstr =~ s/    $//;
    return @out, $indstr.'}';
}

sub unquote {
    local $_ = shift;
    s/\\(.)/$1/g;
    return $_;
}

sub trim {
    local $_ = shift;
    return '' if !defined;
    s/^\s+|\s+$//g;
    return $_;
}

sub fill_placeholders {
    my ($self, $obj, %actions) = @_;
    my %placeholders = placeholders($obj);
    my %order = qw(
        id       00000
        uuid     00001
        title    00002
        location 00003
    );
    my @ordered_placeholders = sort {
        my ($ak, $bk) = map { $_->[0] } $a, $b;
        ($order{$ak} // $ak)
        cmp
        ($order{$bk} // $bk)
    } values %placeholders;
    foreach (@ordered_placeholders) {
        my ($key, $setter, $action, @args) = @$_;
        $key =~ s/^\.// or die "Huh?";
        my $sub = $self->can('ph_'.$action) || $actions{$action} || $actions{'*'}
            || die "Unknown placeholder action: $action";
        $sub->($self, $key, $setter, @args);
        last if !$self->{running};
    }
}


# --- Placeholder handlers

sub ph_mint {
    my ($self, $key, $setter, $m, @etc) = @_;
    my $minter = $self->{config}{minters}{$m} or die "No such minter: $m";
    my ($cmd, $args) = @$minter{qw(command arguments)};
    open my $fh, '-|', $cmd, @{ $args || [] } or die;
    my $val = <$fh>;
    die "$cmd: no value returned" if !defined $val;
    chomp $val;
    $setter->($val);
    my $label = $self->{config}{labels}{$key} // ucfirst $key;
    print STDERR "  $label: $val\n";
}

sub ph_string {
    my ($self, $key, $setter, @args) = @_;
    my $label = $self->{config}{labels}{$key} // ucfirst $key;
    $setter->($self->ask($label));
}

sub ph_list {
    my ($self, $key, $setter, @args) = @_;
    my $label = $self->{config}{labels}{$key} // ucfirst $key;
    $setter->([ split /,\s*/, $self->ask($label) ]);
}

sub ph_location {
    my ($self, $key, $setter, @args) = @_;
    my $label = $self->{config}{labels}{$key} // ucfirst $key;
    my %loc = %{ $self->{config}{locations} || {} };
    my $locmsg = sprintf "Valid locations: %s\n", join(', ', sort keys %loc);
    my $loc = $self->ask($label, 'home', sub {
        return 1 if defined $loc{$_};
        print STDERR $locmsg, "\n";
        return undef;
    });
    $setter->($loc);
}

sub ask {
    my ($self, $label, $default, $validate) = @_;
    if (!$self->{interactive}) {
        return $default if defined $default;
        return if $self->{unaskable};
        die "$label Can't ask -- not running interactively";
    }
    else {
        local $_;
        while (1) {
            my $cancelled;
            local($SIG{INT}) = local($SIG{QUIT}) = local($SIG{TERM}) = sub {
                $cancelled = 1;
            };
            print STDERR "  $label: ";
            print STDERR "[$default] " if defined $default;
            $_ = <STDIN>;
            if ($cancelled) {
                print STDERR "\ncancelled\n";
                $self->{running} = 0;
                die;
            }
            chomp;
            return $default if $_ eq '' && defined $default;
            last if !$validate || $validate->();
        }
        return $_;
    }
}

sub instantiate {
    my ($obj) = @_;
}

sub placeholders {
    my ($hash) = @_;
    my @placeholders = _hash_placeholders($hash);
    return map {
        my $k =  $_->[0];
        $k => $_
    } @placeholders;
}

sub _hash_placeholders {
    my ($hash, @path) = @_;
    my @p;
    while (my ($k, $v) = each %$hash) {
        my $r = ref $v;
        if ($r eq 'HASH') {
            push @p, _hash_placeholders($v, ".$k");
        }
        elsif ($r eq 'ARRAY') {
            push @p, _array_placeholders($v, "[$k]");
        }
        elsif ($r ne '') {
            die "Huh???";
        }
        elsif ($v =~ /^<(.+)>$/) {
            my $setter = sub { $hash->{$k} = shift };
            my ($action, @args) = split /\s*:\s*/, $1;
            push @p, [ join('', @path, ".$k"), $setter, $action, @args ];
        }
    }
    return @p;
}

1;

=pod

=head1 NAME

Ei - manage an inventory of stuff

=cut
