use ExtUtils::MakeMaker;
require 5.006000;
use strict;

use File::Basename;
use File::Spec::Functions qw|:ALL|;
use Config;

my $default_conf = '/etc/webservice_dms/dms.conf';
# Grab out any custom cmdline args
my %args = (
            pkg_name  => 'dms',
            name      => 'Document-Manager',
	    conf      => $default_conf,
            DESTDIR   => undef
            );
my @pass_args;
while (my $arg = shift @ARGV) {
    my ($key, $value) = split /=/, $arg;
    if (exists $args{$key}) {
        $args{$key} = $value;
    } else {
        push @pass_args, $arg;
    }
}
@ARGV = @pass_args;

my $name = $args{'name'};
my %opts = (
            'NAME'	   => $args{'name'},
            'VERSION_FROM' => "lib/Document/Manager.pm",
	    'EXE_FILES'    => [ 
				qw(
				   scripts/dmsd
				   scripts/get_docs
				   scripts/ls_docs
				   scripts/repo_add
				   scripts/repo_export
				   scripts/repo_get
				   scripts/repo_init
				   scripts/repo_ls
				   scripts/repo_put
				   scripts/stat_docs
				   scripts/submit_doc
				   scripts/test_server.sh
				   scripts/update_doc
				   )
                                ], 
            'PREREQ_PM' => {
		'SOAP::Lite'             => 0,
		'SOAP::Lite::Utility'    => 0,
		'SVG::Metadata'          => 0,
		'Config::Simple'         => 0,
                'Carp'                   => 1.00,
		'Pod::Usage'             => 1.00,
                'Getopt::Long'           => 2.00,
                'File::Spec'             => 0,
                'File::Copy'             => 2.00,
                'File::Path'             => 1.00,
                'File::Find'             => 1.00,
		'RDF::Simple'            => 0,
		'WebService::TicketAuth' => 0,
                },
	    'AUTHOR' => 'Bryce Harrington <bryce@bryceharrington.org>',
	    'ABSTRACT' => 'Manages collection of revision-controlled docs'
);

# This puts us in the site_perl directory, not dependant on any version
# of perl.
if (defined($Config{'sitelib_stem'}) && $Config{'sitelib_stem'} ne "") {
    print "stem is: $Config{'sitelib_stem'}\n";
    $opts{'INSTALLSITELIB'} = "";
    $opts{'INSTALLSITELIB'} = $args{'DESTDIR'}
                if ($] >= 5.008 ||
                    $ExtUtils::MakeMaker::VERSION =~ /5\.9[1-6]|6\.0[0-5]/);
    $opts{'INSTALLSITELIB'} .= $Config{'sitelib_stem'};
}

WriteMakefile( %opts );

sub install_clause {
    my ($source, $target_dir, $overwrite) = @_;
    $overwrite = 1 unless (defined($overwrite));

    my $text = '';

    $text .= "install :: $source\n";
    $text .= "\t\$(MKPATH) $target_dir\n";
    $text .= "\t\$(CHMOD) a+rx $target_dir\n";
    if ($source) {
        if (-d $source) {
            # If we're copying a directory, update all permissions of subdirs & files
            $text .= "\tfind $source -type d | xargs \$(CHMOD) a+rx\n";
            $text .= "\tfind $source -type f | xargs \$(CHMOD) a+r\n";
        }
        if ($overwrite) {
            # Copy everything recursively excluding CVS dirs and preserving permissions
            $text .= "\t\$(RSYNC) -Cpr $source $target_dir\n";
        } elsif (-f $source) {
            # Don't over-write
            # (This assumes we're installing a _file_, not a directory tree)
            my $dest_file = catfile( $target_dir, basename( $source ) );
            $text .= "\tif [ -f $dest_file ]; ";
            $text .= "then \$(CP) $source $dest_file.dist; ";
            $text .= "else \$(CP) $source $dest_file; fi\n";
            $text .= "\t\$(CHMOD) -R a+r $dest_file\n";
        } else {
            die "Can't install directory '$source' unless overwrite=1\n";
        }
    }
    $text .= "\n";
    return $text;
}

sub MY::postamble {
    my $self = shift;
    my $text = '';
    my $etcdir = '';

    $text .= "RSYNC = rsync\n";
    $text .= "CHOWN = chown\n\n";

    # Determine location of etc conf files
    my $destdir = $args{DESTDIR} || rootdir();

    my $etcdir   = catdir( $destdir,  'etc', $args{pkg_name} );
    my $etcfiles = catfile( 'etc', "dms.conf" );
  
#    $text .= install_clause($etcfiles, $etcdir, 0);

    if ($args{conf} ne $default_conf) {
	# Substitute config file location into perl module
	# (Yes, this is a bit of a hack...  I'd love to have a better way...)
	$text .= "all :: \$(INST_LIB)/Document/Manager.pm\n";
	$text .= "\techo Setting config path location in Document::Manager\n";
	$text .= qq|\t\$(PERL) -pi -e 's#$default_conf#$args{conf}#g' \$(INST_LIB)/Document/Manager.pm|;
	$text .= "\n\n";
    }

    return $text;
}
# vi:set ai ts=4 sw=4 expandtab:
