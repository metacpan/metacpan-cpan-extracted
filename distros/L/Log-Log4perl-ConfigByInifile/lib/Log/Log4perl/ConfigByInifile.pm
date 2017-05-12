package Log::Log4perl::ConfigByInifile;
use strict;
use warnings;
use Log::Log4perl;
use Params::Validate qw(:all);
use Config::IniFiles;
use Carp;

# $Revision: 10 $
# $Date: 2007-03-16 18:39:40 +0100 (Fri, 16 Mar 2007) $
# $Id: ConfigByInifile.pm 10 2007-03-16 17:39:40Z horshack $
# $HeadURL: http://svn.rosi13.de/svn/Log-Log4perl-ConfigByInifile/trunk/lib/Log/Log4perl/ConfigByInifile.pm $
# $Author: horshack $

BEGIN {
    use base qw(Exporter);
    our $VERSION = '0.04';

    # our @EXPORT      = qw();
    our @EXPORT_OK = qw(ConfigByInifile);

    # our %EXPORT_TAGS = ();
}

=head1 NAME

Log::Log4perl::ConfigByInifile - Get Log::Log4perl config from an ini-File

=head1 VERSION

0.03 - more Perl Best Practices with http://perlcritic.com/perl/critic.pl

=head1 SYNOPSIS

    use Log::Log4perl::ConfigByInifile;
    Log::Log4perl::ConfigByInifile->new(
        { ini_fn => 'acme.ini', }
    );
    my $logger = Log::Log4perl->get_logger('main');
    $logger->debug('Starting...');


=head1 DESCRIPTION

Initialize Log::Log4perl with an ini-File. You must supply a 
section for Log4perl like this:

    [log4perl]
    log4perl.category = INFO, Logfile, Screen 

    log4perl.appender.Logfile          = Log::Log4perl::Appender::File 
    log4perl.appender.Logfile.filename = your_logfile.log
    log4perl.appender.Logfile.mode     = write 

    log4perl.appender.Logfile.layout = Log::Log4perl::Layout::SimpleLayout
    log4perl.appender.Screen         = Log::Log4perl::Appender::Screen 
    log4perl.appender.Screen.layout  = Log::Log4perl::Layout::SimpleLayout

    [myfiles]
    ...

=head1 SUBROUTINES/METHODS


=head2 new

This is the only method this module has. Calling it 
initializes Log::Log4perl with the section [log4perl]
in your inifile.

Usage:

    Log::Log4perl::ConfigByInifile->new(
        { ini_fn => 'acme.ini', }
    );
    my $logger = Log::Log4perl->get_logger('main');
    $logger->debug('Starting...');

or

    my $ini_obj = Config::IniFiles->new(
        -file => 'acme.ini');

    Log::Log4perl::ConfigByInifile->new(
        { ini_obj => $ini_obj, }
    );
    my $logger = Log::Log4perl->get_logger('main');
    $logger->debug('Starting...');

Returns: Nothing. This routine only initializes Log::Log4perl.

Argument: Either ini_file or ini_obj.

Throws: Dies in all kinds of errors with a good message (inifile
does not exist, not even single argument given etc.)

=cut

sub new {
    my $class       = shift;
    my %defaults    = ( section => 'log4perl', );
    my $ini_section = $defaults{section};

    my $args_href = shift;
    %{$args_href} = validate_with(
        params => $args_href,
        spec   => {
            ini_file => {
                type      => SCALAR,
                optional  => 1,
                callbacks => { 'file_must_exist' => sub { -f $_[0] }, },
            },
            ini_obj => {
                type      => OBJECT,
                optional  => 1,
                callbacks => {
                    'must_be_config_inifiles' =>
                      sub { ref $_[0] eq 'Config::IniFiles' },
                },
            },
        }
    );

    # either ini_file _or_ ini_obj
    my $anz_file_obj = 0;
    $anz_file_obj += exists $args_href->{ini_file} ? 1 : 0;
    $anz_file_obj += exists $args_href->{ini_obj}  ? 1 : 0;
    if ( $anz_file_obj != 1 ) {
        confess 'Submit either ini_file or ini_obj to new';
    }

    my $ini_obj;

    if ( $args_href->{ini_obj} ) {
        $ini_obj = $args_href->{ini_obj};
    }
    else {
        $ini_obj = Config::IniFiles->new( -file => $args_href->{ini_file} );
    }

    # At this point there is an ini-Object which points
    # to our ini-file

    if ( !$ini_obj->SectionExists($ini_section) ) {
        confess "There must be a section '$ini_section' in the inifile";
    }

    my $log_conf;
    for my $var ( $ini_obj->Parameters($ini_section) ) {
        next if !defined $var;
        $log_conf .= sprintf "%s=%s\n", $var,
          $ini_obj->val( $ini_section, $var );
    }
    Log::Log4perl::init( \$log_conf );

    # return something (PBP)
    return 1;
}

=head1 DEPENDENCIES

Depends on these Perl modules: 

    Log::Log4perl;
    Params::Validate;
    Config::IniFiles;

=head1 AUTHOR

    Richard Lippmann
    CPAN ID: HORSHACK
    horshack@lisa.franken.de
    http://lena.franken.de

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

=cut

1;
