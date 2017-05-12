#!/usr/bin/perl

=head1 NAME

copy-links-from-users - get link files for use by link-controller

=head1 SYNOPSIS

copy-links-from-users [options] username.. destfile

=head1 DESCRIPTION

This program is designed to check through all of the user's
directories and get lists of links which can then used to build a
central link database using C<extract-links>

B<--user>

B<--group>

=head1 NOTES

This program has not been audited at all for security yet and isn't
safe to run as root.  In the long term, the aim is that this should be
safe to run as root.  However, even so, you should not do that!!!  It
will work better if run as a normal user.

=head1 SEE ALSO

L<default-install>

L<verify-link-control(1)>; L<extract-links(1)>; L<build-schedule>
L<link-report(1)>; L<fix-link(1)>; L<link-report.cgi(1)>; L<fix-link.cgi>
L<suggest(1)>; L<link-report.cgi(1)>; L<configure-link-control>

The LinkController manual in the distribution in HTML, info, or
postscript formats, included in the distribution.

http://scotclimb.org.uk/software/linkcont - the
LinkController homepage.

=cut

$::start_time = time();
$::earliest_modtime=0;
use Getopt::Function; #don't need yet qw(maketrue makevalue);

sub group;

{
  my $opened=0;
  $::opthandler = new Getopt::Function 
    [ "version V>version",
      "usage h>usage help>usage",
      "help-opt=s",
      "verbose:i v>verbose",
      "group=s g>group",
      "output-file=s",
    ],  {
	 #not used.. they should use @ARGV..
	 user => [ sub { $users{$::value}=1; },
		   "copy links from the given username",
		     "USERNAME"],
	 max-age => [ sub {$::earliest_modtime=$start_time
			     - $::value * 60*60*24; },
		      "Maximum age for files to be collected (0=disable)",
		      "DAYS"],
	 group => [
		   sub {
		     my ($name,$passwd,$gid,$members) = getgrnam($::value);
		     die "Unknown group $::value" unless defined($gid);
		     foreach my $user (split / /, ($members)) {
		       $users{$user}=1;
		     }
		   },
		   "copy links from the given group name.",
		   "GROUP",
		  ],
	 #currently inactive
	 "output-file" => [ sub {
			    die "Only one output file supported.  Use tee."
			      if $opened;
			    #not portable
			    open STOUT, "> ./$::value";
			  },   "File into which to gather links.",
			    "FILENAME"
			]
	};
}
$::opthandler->std_opts;

$::opthandler->check_opts;

sub usage() {
  print <<EOF;
copy-links-from-users [options] username [...]

EOF
  $::opthandler->list_opts;
  print <<EOF;

Copy links files from user's directories.
EOF
}

sub version() {
  print <<'EOF';
copy-links-from-users version
$Id: copy-links-from-users.pl,v 1.3 2001/11/22 15:30:29 mikedlr Exp $
EOF
}

foreach my $user (@ARGV) {
  $users{"$user"} = 1;
}

die "no users given" unless keys(%users) ;

USER: foreach my $user ( keys (%users) ) {
  print STDERR "considering copying from user $user\n" if $verbose;
  my ($uname,$upasswd,$uuid,$ugid, $uquota,$ucomment,$ugcos,$udir,
      $ushell,$uexpire)
    = getpwnam($user);
  die "Unknown user $user" unless defined($uuid);
  die "User $user has UID < 100" if $uuid < 100;
  #FIXME arbitrary parameter (100) which is often wrong, e.g. on redhat where
  #500 would be correct!!
  #FIXME maybe we should.  Just delete this line.

  my $link_file=$udir . '/.link-control-links';
  if ( -e $link_file ) {
    sysopen (USR_LNK_FILE, $link_file, $rdonly) || do {
      warn "couldn't open users link file for $user";
      next USER;
    };
    my ($fdev,$fino,$fmode,$fnlink,$fuid,$fgid,$frdev,$fsize,
     $fatime,$fmtime,$fctime,$fblksize,$fblocks) = stat(USR_LNK_FILE);

    next USER if $::earliest_modtime && $fmtime < $::earliest_modtime ;

    #the target user must own the file.  Anything else is his responsibility
    $uuid != $fuid and do {warn "File $link_file not owned by $user";
			   next USER;};
    print STDERR "$link_file will be copied \n" if $verbose;
    print "#####################################################################\n";
    print "#links from user $uname from file $link_file\n";
    print "#####################################################################\n";

    #FIXME statistics?
    while (<USR_LNK_FILE>) {
      print || die "print failed $!";
    }

  }
  # we should only allow ourselves to open a file iff
  # we have access to it (easy)
  # the current user has access to it.
  # FIXME ?? no other user has modification rights.
}

close STDIN or die "couldn't close stdin $!";


