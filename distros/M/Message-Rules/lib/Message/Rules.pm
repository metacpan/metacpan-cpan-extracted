package Message::Rules;
$Message::Rules::VERSION = '1.150170';
$Message::Rules::VERSION = '1.142101';
{
  $Message::Rules::VERSION = '1.132770';
}

use strict;use warnings;
use Message::Match qw(mmatch);
use Message::Transform qw(mtransform);
use File::Find;
use JSON;

sub new {
    my $class = shift;
    my $self  = {};
    bless ($self, $class);
    return $self;
}

{
my @loaded_configs;
my $add_config = sub {
    my $thing = shift;
    return if $thing->{is_not_a_rule};
    $thing->{order} = 0 unless $thing->{order};
    push @loaded_configs, $thing;
};
my $wanted = sub {
    my $f = $File::Find::name;
    $f =~ s/.*\///;
    return unless -f $f;
    return if $f =~ /\/\./;
    my $contents;
    eval {
        open my $fh, '<', $f or die "open of $f failed: $!\n";
        read $fh, $contents, 10240000 or die "read of $f failed: $!\n";
        close $fh or die "close of $f failed: $!\n";
    };
    die "Message::Rules::load_rules_from_directory: $@\n" if $@;
    my $conf;
    eval {
        $conf = decode_json $contents or die 'failed to decode_json';
    };
    return unless $conf;
    if(not ref $conf) {
#        die "Message::Rules::load_rules_from_directory: $f did not contain a reference";
        return;
    }
    if(ref $conf eq 'HASH') {
        $add_config->($conf);
        return;
    }
    if(ref $conf eq 'ARRAY') {
        $add_config->($_) for @{$conf};
        return;
    }
    die "Message::Rules::load_rules_from_directory: $f did not contain either a HASH or ARRAY reference";
    return;
};
my $get_sorted_configs = sub {
    my @configs = sort { $a->{order} <=> $b->{order}} @loaded_configs;
    @loaded_configs = ();
    return \@configs;
};

sub load_rules_from_directory {
    my $self = shift;
    my $directory = shift;
    die "Message::Rules::load_rules_from_directory: passed directory ($directory) does not exist\n"
        if not -e $directory;
    die "Message::Rules::load_rules_from_directory: passed directory ($directory) is not a directory\n"
        if not -d $directory;
    find($wanted, $directory);
    $self->{rules} = $get_sorted_configs->();
    return $self->{rules};
}
}

sub apply_rules {
    my $self = shift;
    my $messages = shift;
    while(my($key,$value) = each %$messages) {
        my $message = $value;
        $self->merge_rules($message);
        $messages->{$key} = $message;
    }
    return $messages;
}

sub output_apply_rules {
    my $self = shift;
    my $incoming_directory = shift;
    my $outgoing_directory = shift;
    my $messages = $self->load_messages($incoming_directory);
    $self->apply_rules($messages);
    while(my($filename, $message) = each %$messages) {
        eval {
            my $path = "$outgoing_directory/$filename";
            open my $fh, '>', $path or die "failed to open $path for write: $!";
            print $fh JSON->new->canonical(1)->pretty(1)->encode($message);
            close $fh or die "failed to close $path: $!";
        };
        die "Message::Rules::output_apply_rules: (\$filename=$filename): failed: $@\n" if $@;
    }
    return 1;
}

sub load_messages {
    my $self = shift;
    my $directory = shift;
    my $messages = {};
    eval {
        die 'passed argument not a readable directory'
            if not -d $directory or not -r $directory;
        local $SIG{ALRM} = sub { die "timed out\n"; };
        alarm 5;
        opendir (my $dh, $directory) or die "opendir failed: $!";
        my @files = grep { -f "$directory/$_" and not "$directory/$_" =~ /^\./ } readdir($dh);
        closedir $dh or die "closedir failed: $!";
        foreach my $filename (@files) {
            my $contents;
            open my $fh, "$directory/$filename" or die "failed to open file ($filename): $!";
            read $fh, $contents, 1024000 or die "failed to read ($filename): $!";
            close $fh or die "failed to close file ($filename): $!";
            my $conf = decode_json $contents or die 'failed to decode_json';
            $messages->{$filename} = $conf;
        }
    };
    alarm 0;
    die "Message::Rules::load_messages: failed (\$directory=$directory) $@\n"
        if $@;
    return $messages;
}

sub merge_rules {
    my $self = shift;
    my $message = shift;

    foreach my $conf (@{$self->{rules}}) {
        next unless mmatch $message, $conf->{match};
        mtransform($message, $conf->{transform});
    }
    return $message;
}


1;

__END__

=head1 NAME

Message::Rules - Apply a pile of rules to incoming messages

=head1 SYNOPSIS

    use Message::Rules;

=head1 DESCRIPTION

    my $r = Message::Rules->new();
    $r->load_rules_from_directory('conf/dir');
    my $m = $r->merge_rules({main => 'thing'});


=head1 METHODS

=head2 load_rules_from_directory($directory);

Iterate through the passed directory tree and load all of
the rules found therein.

=head2 merge_rules($message);

Pass $message through the loaded ruleset, and return the
updated message.

=head1 TODO

Tons.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2013 Dana M. Diederich. All Rights Reserved.

=head1 AUTHOR

Dana M. Diederich <dana@realms.org>

=cut

