=head1 NAME

MKDoc::Setup::Core - Deploys MKDoc::Core master directory.


=head1 SYNOPSIS

  perl -MMKDoc::Setup -e install_core /usr/local/mkdoc-core


=head1 SUMMARY

L<MKDoc::Core> is an application framework which aims at supporting easy-ish
installation and management of multiple MKDoc products onto multiple virtual
hosts / websites.

Before you can install L<MKDoc::Core> sites, you need to install L<MKDoc::Core>
in a master directory where the software can maintain various default
configuration files and other things. You only need to do this once.


=head1 PRE-REQUISITES

=over 4

=item Perl 5.8.0 or greater

=item Apache + mod_perl

=item A decent Unix/Linux system.

=back


=head1 SETTING UP

First you need to choose a master directory for L<MKDoc::Core>, e.g.

  /usr/local/mkdoc-core

It is not necessary to be root in order to install MKDoc::Core, so it would be
appropriate to create this directory as root and then change the permissions to
an unprivileged user.


Then you need to run the MKDoc::Core setup as follows:

  perl -MMKDoc::Setup -e install_core /usr/local/mkdoc-core


The screen will look like this:

  1. MKDoc Directory        /usr/local/mkdoc-core

  D. Delete an option

  I. Install with the options above
  C. Cancel installation


Press 'i' and enter to proceed. Once this is done, provided there were no
errors you should add the following line in your httpd.conf file:

  NameVirtualHost *
  Include /usr/local/mkdoc-core/conf/httpd.conf

If everything went OK, you should immediately proceed to installing your first
L<MKDoc::Core> site. Consult L<MKDoc::Setup::Site> for details on how to do
this.

=cut
package MKDoc::Setup::Core;
use strict;
use warnings;
use File::Spec;
use base qw /MKDoc::Setup/;


sub main::install_core
{
	$::MKDOC_DIR = shift (@ARGV);
	__PACKAGE__->new()->process();
}


sub keys { qw /MKDOC_DIR/ }


sub label
{
    my $self = shift;
    $_ = shift;
    /MKDOC_DIR/ and return "MKDoc Directory";
    return;
}


sub initialize
{
    my $self = shift;
    $self->{MKDOC_DIR} = $::MKDOC_DIR || $ENV{MKDOC_DIR} || '/usr/local/mkdoc';
}


sub validate
{
    my $self = shift;
    my $cur_dir = $self->{MKDOC_DIR};

    $cur_dir    = File::Spec->rel2abs ($cur_dir);
    $cur_dir    =~ s/\/$//;

    -d $cur_dir or mkdir $cur_dir or do {
        print "Impossible to create $cur_dir";
        return 0;
    };

    -d "$cur_dir/conf" or mkdir "$cur_dir/conf" or do {
        print "Impossible to create $cur_dir/conf";
        return 0;
    };

    $self->{MKDOC_DIR} = $cur_dir;
    return 1;
}


sub install
{
    my $self = shift;
    my $cur_dir = $self->{MKDOC_DIR};

    $cur_dir    = File::Spec->rel2abs ($cur_dir);
    $cur_dir    =~ s/\/$//;

    -d $cur_dir        or do { mkdir $cur_dir        || die "Cannot create $cur_dir. Reason: $!" };
    -d "$cur_dir/conf" or do { mkdir "$cur_dir/conf" || die "Cannot create $cur_dir. Reason: $!" };
    -d "$cur_dir/cgi"  or do { mkdir "$cur_dir/cgi"  || die "Cannot create $cur_dir. Reason: $!" };

    chmod 0755, $cur_dir, "$cur_dir/conf", "$cur_dir/cgi";


    print "\n\n";
    $self->install_mksetenv();
    $self->install_httpd_conf();
    $self->install_mkdoc_cgi();
    $self->install_success();
    exit (0);
}


sub install_mksetenv
{
    my $self = shift;
    my $cur_dir = $self->{MKDOC_DIR};

    open FP, ">$cur_dir/mksetenv.sh" || die "Cannot create '$cur_dir/mksetenv.sh'";
    print FP join "\n", (
	qq |export MKDOC_DIR="$cur_dir"|,
       );
    print FP "\n";
    close FP;

    chmod 0644, "$cur_dir/mksetenv.sh";
}


sub install_httpd_conf
{
    my $self = shift;
    my $cur_dir = $self->{MKDOC_DIR};

    open FP, ">>$cur_dir/conf/httpd.conf" || die "Cannot touch $cur_dir/conf/httpd.conf. Reason: $!";
    print FP '';
    close FP;

    chmod 0644, "$cur_dir/conf/httpd.conf";
}


sub install_mkdoc_cgi
{
    my $self = shift;
    my $cur_dir = $self->{MKDOC_DIR};

    open FP, ">$cur_dir/cgi/mkdoc.cgi";
    print FP join '', <DATA>;
    close FP;

    chmod 0755, "$cur_dir/cgi/mkdoc.cgi";
}


sub install_success
{
    my $self = shift;
    my $cur_dir = $self->{MKDOC_DIR};

    print "Successfully created $cur_dir/mksetenv.sh\n\n";
    print "At this point you probably should add the following in your Apache httpd.conf file:\n\n";

    print "# Include all MKDoc sites\n";
    print "Include $cur_dir/conf/httpd.conf\n\n";
}



1;


__DATA__
#!/usr/bin/perl
use MKDoc::Core;
use Data::Dumper;
use strict;
use warnings;

eval { MKDoc::Core->process() };
if (defined $@ and $@)
{
    print "Status: 500 Internal Server Error\n";
    print "Content-Type: text/html; charset=UTF-8\n\n";
    if (ref $@) { $@ = Dumper ($@) }
    $@ = Dumper (\%ENV) . "\n\n" . $@;
    warn "SOFTWARE_ERROR\n\n" . $@ . "\n\n";
}

BEGIN {
    $SIG{'__WARN__'} = sub {
        # trap some common error strings that otherwise flood the error log files
        warn $_[0] unless ($_[0] =~ /byte of utf8 encoded char at/ or
                           $_[0] =~ /is deprecated/                or
                           $_[0] =~ /IMAPClient\.pm line/);
    }
}
