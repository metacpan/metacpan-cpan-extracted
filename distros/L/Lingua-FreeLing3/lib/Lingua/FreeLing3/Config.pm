package Lingua::FreeLing3::Config;

use Lingua::FreeLing3::ConfigData;
use File::Spec::Functions 'catfile';

use warnings;
use strict;

our $VERSION = "0.1";

sub new {
    my $class = shift;
    my $language = shift;

    my $prefix = Lingua::FreeLing3::ConfigData->config('fl_datadir');
    my $configfile = catfile($prefix, "config", "$language.cfg");

    die "Can't find config file for language '$language'" unless -f $configfile;

    my ($fh, $config);
    open $fh, "<", $configfile or die "Can't open config file for language '$language'";

    local $/ = "\n";
    while (<$fh>) {
        chomp;
        s/#.*//;
        next if /^\s*$/;

        if (/^([^= ]+)\s*=\s*(.*)/) {
            my ($key, $value) = ($1, $2);
            $value =~ s/\$FREELINGSHARE/$prefix/;
            $config->{$key} = $value;
        }
    }

    close $fh;

    return bless $config => $class;
}

sub config {
    my ($self, $key) = @_;
    if (exists($self->{$key})) {
	return $self->{$key}
    } else {
	use Data::Dumper;
	die "Queried for $key on a config file the doesn't include it\n", Dumper($self);
    }
}

=encoding UTF-8

=head1 NAME

Lingua::FreeLing3::Config - Interface to FreeLing3 config files

=head1 SYNOPSIS

  use Lingua::FreeLing3::Config;
  my $conf = Lingua::FreeLing3::Config->new('es');

  my $tokenizer_data = $conf->config("TokenizerFile");

=head1 DESCRIPTION

This module is not intented to be used directly, unless you are
messing with the FL3 internals.

=head1 METHODS

=head2 C<new>

Loads a configuration file from disk. Returns an object. Receives as
argument the language name.

=head2 C<config>

Given a config key, returns its value. Note this module is not
intended to change the config file, so this is B<NOT> an accessor.

perl(1)

=head1 AUTHOR

Alberto Manuel Brandão Simões, E<lt>ambs@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Alberto Manuel Brandão Simões

=cut


1;
