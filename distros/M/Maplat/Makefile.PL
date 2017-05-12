use 5.010000;
use ExtUtils::MakeMaker;

my $lib;
BEGIN {
    use vars qw/$sep/;
    my %sep = (
               MacOS   => ':',
               MSWin32 => '\\',
               os2     => '\\',
               VMS     => '\\',
               NetWare => '\\',
               dos     => '\\',
               );
    $sep = $sep{$^O} || '/';
    $lib = join $sep, 't', 'lib';
}

use lib $lib;
if ($VERSION =~ /_/) {
    print "WARNING! This is a test version ($VERSION) and should not be used in production!\n";
}

# We need the version information to properly set compiler options later
# Use App::Info to get the data we need.
require App::Info::RDBMS::PostgreSQL;
require App::Info::Handler::Prompt;
my $p = App::Info::Handler::Prompt->new;
#my $pg = App::Info::RDBMS::PostgreSQL->new(on_unknown => $p);
my $pg = App::Info::RDBMS::PostgreSQL->new();
my ($major_ver, $minor_ver, $patch, $conf, $bindir) = map {$pg->$_}
    qw/major_version minor_version patch_version configure bin_dir/;
my $initdb = '';
if (defined $bindir and -d $bindir) {
    my $testinitdb = "$bindir${sep}initdb";
    if (-e $testinitdb) {
        $initdb = $testinitdb;
    }
}


{
    package MY; ## no critic
    sub MY::test { ## no critic
        my $string = shift->SUPER::test(@_);
        $string =~ s/(PERL_DL_NONLAZY=1)/PGINITDB="$initdb" $1/g;
        return $string;
    }
}


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Maplat',
    VERSION_FROM      => 'lib/Maplat.pm', # finds $VERSION
    PREREQ_PM         => {
            "Archive::Zip" => 0,
            "Carp" => 0,
            "CGI" => 0,
            "Data::Dumper" => 0,
            "Date::Manip" => 0,
            "Date::Simple" => 0,
            "Date::Parse" => 0,
            "DBI" => 0,
            "DBD::Pg" => 0,
            "Date::Simple" => 0,
            "Digest::MD5" => 0,
            "Digest::SHA1" => 0,
            "English" => 0,
            "Errno" => 0,
            "FileHandle" => 0,
            "File::Spec" => 0,
            "File::stat" => 0,
            "File::Temp" => 0,
            "Getopt::Long" => 0,
            "HTTP::Server::Simple::CGI" => 0,

            # FIXME: HTML::FormatText is broken
            #"HTML::FormatText" => 0,

            "HTML::Parse" => 0,
            "IO::Handle" => 0,
            "IO::Socket::SSL" => 0,
            "Mail::Sendmail" => 0,
            "MIME::Base64" => 0,
            "MIME::QuotedPrint" => 0,
            "Net::Server::PreFork" => 0,
            "Net::SSLeay" => 0,
            "PDF::Report" => 0,
            "Socket" => 0,
            "Storable" => 0,
            "String::CRC32" => 0,
            "Sys::Hostname" => 0,
            "Template" => 0,
            "Test::More" => 0,
            "Time::HiRes" => 0,
            "XML::Simple" => 0,
            "YAML::XS" => 0,
            "Weather::Google" => 0,
            "WWW::Mechanize" => 0,
            GD        => 0,
            "GD::Graph"    => 0,
            "Net::Ping" => 0,
            "Readonly" => 0,
            "HTML::TableExtract"    => 0,
            "Net::SNMP"    => 0,

            # tcp tunnel stuff for VNC
            "POE::Component::Proxy::TCP" => 0,
            "POE::Filter::Stream" => 0,
            "POE::Filter::Line" => 0,

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Maplat.pm', # retrieve abstract from module
       AUTHOR         => 'Rene Schickbauer <rene.schickbauer@gmail.com>') : ()),
);
