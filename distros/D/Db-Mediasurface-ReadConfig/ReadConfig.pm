package Db::Mediasurface::ReadConfig;
$VERSION = '0.01';
use strict;
use vars qw( $AUTOLOAD );
use Carp;

sub new
{
    my ($class,%arg) = @_;
    my $self = {
	_config_file => $arg{path} || croak("need path to config file"),
	_config_tree => undef
    };
    croak("config file does not exist") unless -T $self->{_config_file};
    my $obj = bless $self, $class;
    $obj->_parse_config;
    return $obj;
}

sub _parse_config
{
    my $self = $_[0];
    return if defined $self->{_config_tree};
    use Fcntl;
    sysopen(CONFIG, $self->{_config_file}, O_RDONLY)
	or croak("Couldn't open ".$self->{_config_file}." for reading: $!\n");
    while (my $line = <CONFIG>){
	chomp($line);
	$line =~ s/#.*$//;
	my ($key,$value) = split /=/, $line;
	next unless defined $value;
	$key =~ s/\s//g;
	$key =~ s/\./_/g;
	if ($value =~ /"(.*?)"/){
	    $value = $1;
	} elsif ($value =~ /(\d+)/) {
	    $value = $1;
	} else {
	    $value =~ s/\s//g;
	}
	$value =~ s/([^\\]|^)\$([a-zA-Z_][a-zA-Z0-9_]*)/$self->{_config_tree}->{$2}/eg;
	my $method = "set_$key";
	$self->$method($value);
    }
    close(CONFIG)
	or croak("Couldn't close ".$self->{_config_file}.": $!\n");
}

sub AUTOLOAD
{
    no strict "refs";
    my ($self, $newval) = @_;
    if ($AUTOLOAD =~ /.*::get_([a-zA-Z0-9_]+)/)
    {
	my $attr_name = $1;
	*{$AUTOLOAD} = sub { return $_[0]->{_config_tree}->{$attr_name} };
	return $self->{_config_tree}->{$attr_name};
    }
    if ($AUTOLOAD =~ /.*::set_([a-zA-Z0-9_]+)/)
    {
	my $attr_name = $1;
	*{$AUTOLOAD} = sub { $_[0]->{_config_tree}->{$attr_name} = $_[1]; return; };
	$self->{_config_tree}->{$attr_name} = $newval;
	return;
    }
}
1;

=head1 NAME

Db::Mediasurface::ReadConfig - reads, parses, and stores configuration from a Mediasurface ms.properties file.

=head1 VERSION

This document refers to version 0.01 of DB::Mediasurface::ReadConfig, released August 3, 2001.

=head1 SYNOPSIS

    use Db::Mediasurface::ReadConfig;

my $path = '/opt/ms/3.0.2/etc/ms.properties';

my $config = Db::Mediasurface::ReadConfig->new( path=>$path );

print('oracle user is '.$config->get_username."\n");

=head1 DESCRIPTION

=head2 Overview

When supplied with a path to a Mediasurface configuration file (usually called ms.properties), this module loads the configuration details into an object, which can be interrogated at a later time.

=head2 Constructor

=over 4

=item $config = Db::Mediasurface::ReadConfig->new( path=>$path );

This class method constructs a new configuration object by reading the file at location $path. This module assumes that the configuration file is constructed in the following manner...

Each key/value pair occurs on a single line, and the key and value are separated by an equals sign (=) and (optionally) white space. Any text on a line is ignored which follows a hash symbol (#).

=back

=head2 Methods

=over 4

=item $value = $config->get_SOME_CONFIG_KEY;

Returns the value associated with a particular configuration key. If the key contained a full-stop in the config file, this is replaced by an underscore. For example, to get the value associated with jdbc.driver in the config file, use $config->get_jdbc_driver

=item $config->set_SOME_CONFIG_KEY($value);

Sets the value of a given key. Does not write the value back to the config file - no permanent damage is done ;)

=back

=head1 AUTHOR

Nigel Wetters (nwetters@cpan.org)

=head1 COPYRIGHT

Copyright (c) 2001, Nigel Wetters. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the same terms as Perl itself.

