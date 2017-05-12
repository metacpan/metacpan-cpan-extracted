package Google::Spreadsheet::Agent::DB;

use FindBin;
use YAML::Any qw/LoadFile/;
use Net::Google::Spreadsheets;
use Moose;
use Carp;

our $VERSION = '0.02';

has 'config_file' => (
                      is => 'ro',
                      isa => 'Str',
                      );

has 'config' => (
                 is => 'ro',
                 builder => '_build_config'
                 );

has 'google_db' => (
                    is => 'ro',
                    builder => '_build_google_db',
                    lazy => 1, # depends on config
                    init_arg => undef # google_db cannot be overridden
                    );

#### BUILDERS

sub BUILD {
    my $self = shift;

    my @required_key_fields = grep { $self->config->{key_fields}->{$_}->{required} } keys %{$self->config->{key_fields}};
    croak "Your configuration must have at least one required key_fields key!\n" unless (@required_key_fields);
}

sub _build_config {
    my $self = shift;
    my $config_file = $self->config_file || $FindBin::Bin.'/../config/agent.conf.yml';
    croak "Config ${config_file} not found!\n" unless (-e $config_file);
    return YAML::Any::LoadFile($config_file);
}

sub _build_google_db {
    my $self = shift;
    my $service = Net::Google::Spreadsheets->new(
                                                 username => $self->config->{guser},
                                                 password => $self->config->{gpass},
                                                 );
    return $service->spreadsheet({
        title => $self->config->{spreadsheet_name}
    });
}

1; # End of Google::Spreadsheet::Agent::DB

__END__

=head1 NAME

Google::Spreadsheet::Agent::DB - Base Net::Google::Spreadsheet object used by Agents and Runners

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This is not meant to be used by itself.  It is meant to be extended in other classes.

=head1 CONFIGURATION

  Scripts which use objects which extend Google::Spreadsheet::Agent::DB must supply
  the appropriate configuration for it to work.  This can be done one of three ways.

=over 3

=item YAML file supplied as config_file constructor argument.

  This is the easiest way to configure a set of agents using the same configuration.
  See config/agent.conf.yml.tmpl for a template, with documentation, of what needs
  to be defined.

=item no config or config_file arguments passed in at all.

  This causes the object to look for YAML file called 'agent.conf.yml' in a directory
  called 'config' in the same root directory as the directory containing the script
  using the Google::Spreadsheet::Agent::DB extending object,
  e.g. $FindBin.'/../config/agent.conf.yml'

=item HashRef supplied as config constructor argument.

  You can define a HashRef with all of the key-value pairs defined in config/agent.conf.yml.tmpl
  and pass that to the constructor.  This may be more useful where you want to use other serialization
  systems (e.g. JSON, XML, etc) to store configuration, which can be manipulated into a HashRef to
  be passed into the constructor.

=back

=head1 METHODS

=head2 google_db

 This returns the actual Net::Google::Spreadsheet object used
 by the agent, in case other types of queries, or modifications
 need to be made that do not fit within this system.


=head1 AUTHOR

Darin London, C<< <darin.london at duke.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-google-spreadsheet-agent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Google-Spreadsheet-Agent>.  I will be
notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Google::Spreadsheet::Agent::DB


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-Spreadsheet-Agent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Google-Spreadsheet-Agent>

=back

=head1 SEE ALSO

L<Google::Spreadsheet::Agent::Runner>
L<Google::Spreadsheet::Agent>
L<Net::Google::Spreadsheets>
L<Moose>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Darin London.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
