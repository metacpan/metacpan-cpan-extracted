package Directory::Deploy::Manifest;

use Moose;

use Directory::Deploy::Carp;

use Path::Abstract;
use Scalar::Util qw/looks_like_number/;

has _entry_map => qw/is ro required 1/, default => sub { {} };

sub normalize_path {
    my $self = shift;
    my $path = shift;

    croak "Wasn't given a path" unless defined $path;

    $path = Path::Abstract->new( $path );
    s/^\///, s/\/$// for $$path;
    return $path;
}

sub _enter {
    my $self = shift;
    my $entry = shift;
    $self->_entry_map->{$entry->path} = $entry;
    return $entry;
}

has include_parser => qw/is ro required 1 isa CodeRef/, default => sub { sub {
    my $self = shift;
    chomp;
    return if m/^\s*$/ || m/^\s*#/;
    my ($path, $content_source) = m/^\s*(\S+)(?:\s*(.*)\s*)?$/;
    s/^\s*//, s/\s*$// for $path;
    $self->add( path => $path, content_source => $content_source );
} };
sub include {
    my $self = shift;
    if (1 == @_ || ref $_[0] eq 'SCALAR') {
        my $parse = shift;
        croak "More than one argument passed to include" if @_;
        my $parser = $self->include_parser;
        $parse = $$parse if ref $_[0] eq 'SCALAR';
        $parser->( $self, $_ ) for split m/\n/, $parse;
    }
    else {
        while (@_) {
            my $path = shift;
            my $value = shift;
            $self->add( $path => (ref $value eq 'HASH' ? %$value : $value) );
        }
    }
}

sub add {
    my $self = shift;
    my %entry;
    if (1 == @_) {
        $entry{path} = shift;
    }
    elsif (2 == @_ && $_[0] && $_[0] ne 'path') {
        $entry{path} = shift;
        my $source_or_content = shift;
        if (ref $source_or_content eq 'SCALAR') {
            $entry{content} = $source_or_content;
        }
        elsif (! ref $source_or_content) {
            $entry{content_source} = $source_or_content;
        }
        else {
            confess "Huh, don't know what $source_or_content is";
        }
    }
    elsif (@_ % 2) {
        $entry{path} = shift;
    }

    my $entry = Directory::Deploy::Manifest::Entry->new( %entry, @_ );
    $self->_enter( $entry );
    return $entry;
}

sub lookup {
    my $self = shift;
    my $path = shift;

    croak "Wasn't given a path" unless defined $path;

    $path = $self->normalize_path( $path );

    return $self->_entry_map->{$path};
}

sub entry {
    return shift->lookup( @_ );
}

sub each {
    my $self = shift;
    my $code = shift;

    for (sort keys %{ $self->_entry_map }) {
        $code->( $self->lookup( $_ ), @_ );
    }
}

package Directory::Deploy::Manifest::Entry;

use Moose;

use Directory::Deploy::Carp;

has is_file => qw/is rw/;
sub is_dir { return ! shift->is_file }
has mode => qw/is rw isa Maybe[Int]/;
has path => qw/is ro required 1/;
has comment => qw/is rw isa Maybe[Str]/;
has content => qw/is rw/;
has content_source => qw/is rw/;

sub path_like_file {
    my $self = shift; # Probably $class
    my $path = shift;

    my $trailing_slash = $path =~ m/\/(?::\d+)?$/; # Optional octal mode at the end

    return ! $trailing_slash;
}

sub parse_path {
    my $self = shift; # Probably $class
    my $path = shift;

    croak "Wasn't given a path to parse" unless defined $path && length $path;

    my $mode;
    $mode = oct $1 if $path =~ s/:(\d+)$//;
    
    my $is_file;
    $is_file = ! ($path =~ s{/+$}{}); # Trailing slash(es) is a directory indicator

    return (
        Directory::Deploy::Manifest->normalize_path( $path ), 
        $is_file,
        $mode,
    );
}

sub BUILD {
    my $self = shift;
    my $given = shift;

    my ($path, $is_file, $mode) = $self->parse_path( $self->path );

    if ($given->{is_dir}) {
        $self->is_file( 0 );
    }
    elsif ($given->{is_file}) {
    }
    else {
        $self->is_file( $is_file );
    }

    unless (defined $given->{mode}) {
        $self->mode( $mode );
    }

    $self->{path} = $path;
}

1;

__END__
#sub add {
#    my $self = shift;
#    my $kind = shift;
#    croak "You didn't specify a kind" unless defined $kind;
#    
#    if ($kind eq 'file') {
#        $self->file( @_ );
#    }
#    elsif ($kind eq 'dir') {
#        $self->dir( @_ );
#    }
#    else {
#        croak "Don't understand kind $kind";
#    }
#}

#sub file {
#    my $self = shift;
#    my %entry;
#    if (1 == @_) {
#        $entry{path} = shift;
#    }
#    elsif (2 == @_ && ref $_[1] eq 'SCALAR') {
#        $entry{path} = shift;
#        $entry{content} = shift;
#    }
#    elsif (3 == @_) {
#        $entry{path} = shift;
#        if (ref $_[0] eq 'SCALAR' && $_[1] =~ m/^\d+$/) {
#            $entry{content} = shift;
#            $entry{mode} = shift;
#        }
#        elsif (ref $_[1] eq 'SCALAR' && $_[0] =~ m/^\d+$/) {
#            $entry{mode} = shift;
#            $entry{content} = shift;
#        }
#    }
#    elsif (@_ % 2) {
#        $entry{path} = shift;
#    }

#    my $entry = Directory::Deploy::Manifest::Entry->new( %entry, @_ );
#    $self->_enter( $entry );
#    return $entry;
#}

#sub dir {
#    my $self = shift;
#    my %entry;
#    if (1 == @_) {
#        $entry{path} = shift;
#    }
#    elsif (@_ % 2) {
#        $entry{path} = shift;
#    }

#    my $entry = Directory::Deploy::Manifest::Dir->new( %entry, @_ );
#    $self->_enter( $entry );
#    return $entry;
#}

#has _entry_list => qw/is ro required 1/, default => sub { {} };

#sub _entry {
#    my $self = shift;
#    return $_[0] if @_ == 1 && blessed $_[0];
#    return Directory::Deploy::Manifest::Om::Manifest::Entry->new(@_);
#}

#sub entry_list {
#    return shift->_entry_list;
#}

#sub entry {
#    my $self = shift;
#    return $self->_entry_list unless @_;
#    my $path = shift;
#    return $self->_entry_list->{$path};
#}

#sub all {
#    my $self = shift;
#    return sort { $a cmp $b } keys %{ $self->_entry_list };
#}

#sub add {
#    my $self = shift;
#    my $entry = $self->_entry(@_);
#    $self->_entry_list->{$entry->path} = $entry;
#}

#sub each {
#    my $self = shift;
#    my $code = shift;

#    for (sort keys %{ $self->_entry_list }) {
#        $code->($self->entry->{$_})
#    }
#}

#sub include {
#    my $self = shift;

#    while (@_) {
#        local $_ = shift;
#        if ($_ =~ m/\n/) {
#            $self->_include_list($_);
#        }
#        else {
#            my $path = $_;
#            my %entry;
#            %entry = %{ shift() } if ref $_[0] eq 'HASH';
#            # FIXME Should we do it this way?
#            my $comment = delete $entry{comment};
#            $self->add(path => $_, comment => $comment, stash => { %entry });
#        }
#    }
#}

#sub _include_list {
#    my $self = shift;
#    my $list = shift;

#    for (split m/\n/, $list) {
#        $self->parser->($self);
#    }
#}


package Directory::Deploy::Manifest::File;

use Moose;

with qw/Directory::Deploy::Manifest::DoesEntry/;

sub is_file { 1 }

package Directory::Deploy::Manifest::Dir;

use Moose;

with qw/Directory::Deploy::Manifest::DoesEntry/;

sub is_file { 0 }

1;

__END__

use Moose;

has comment => qw/is ro isa Maybe[Str]/;
has stash => qw/is ro required 1 isa HashRef/, default => sub { {} };
has process => qw/is rw isa Maybe[Str|HashRef]/;

sub content {
    return shift->stash->{content};
}

sub copy_into {
    my $self = shift;
    my $hash = shift;
    while (my ($key, $value) = each %{ $self->stash }) {
        $hash->{$key} = $value;
    }
}

1;
