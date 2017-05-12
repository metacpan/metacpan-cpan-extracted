use lib 'lib/'; #for next use line:
use FAQ::OMatic::Entropy;

use Config;
$perl = $Config{'perlpath'};

use Digest::MD5 qw(md5_hex);

# we would like to get INSTALLSITELIB the same way, but
# it depends on how Makefile.PL was invoked. If users use PREFIX=...,
# that value gets encoded in INSTALLSITELIB, but %Config doesn't see it.
# Hence the tricky mess of passing the value from Makefile.PL into the
# Makefile to here.
# $inc = $Config{'installsitelib'};
$inc = (grep {m/^INSTALLSITELIB=/} @ARGV)[0] || '';
$inc =~ s/^INSTALLSITELIB=// or die "fom.PL: INSTALLSITELIB= argument missing.\n";

my $temppass = FAQ::OMatic::Entropy::gatherRandomString();

# now use md5 as a 128-bit version of the 56-bit crypt() we used to use.
my $cryptpass = md5_hex($temppass);

# why bother crypt()ing the password in the fom.pl CGI stub if it's
# flying around the net in the clear? Because if the CGI is somehow
# both readable and executable, then we've reopened the window of
# trivial vulnerability for that site.

open THECGI, ">fom" or die "Writing \"fom\": $!";
print THECGI "#!$perl -wT\n";
print THECGI "use lib '.';			# for suid installations\n";
print THECGI "use lib '$inc';\n";

print THECGI <<'EOF';

## Uncomment following two lines (and replace second argument for
## setlocale()) if you want to use some locale, different from default.

# use POSIX qw(locale_h);
# $ENV{LANG} = 'ja_JP.EUC';
# POSIX::setlocale(LC_ALL, $ENV{LANG});

use locale;
EOF

print THECGI "\$ENV{'PATH'} = '';	# for suid installations\n";
print THECGI "\$temporaryCryptedPassword = 7;  # avoid bogus warning\n";
print THECGI "\$temporaryCryptedPassword = '$cryptpass';\n";

print THECGI "use FAQ::OMatic::dispatch;\n";
print THECGI "FAQ::OMatic::dispatch::main('fom-meta/');\n";
close THECGI;
chmod 0755, "fom";

print <<"__EOF__";

If this is a new FAQ-O-Matic, you will need the following
temporary password to complete the installation. (This helps
prevent half-installed systems from being vulnerable.)

Your temporary installation password is:  $temppass
Write it down; you will need it to complete the installation.

If this is a new installation, when 'make install' is complete,
you will need to copy the CGI stub 'fom' into the appropriate CGI
directory, rename it if necessary for your site, set its permissions,
and access it from the web.

Finally, you may get this error at the end of make install:
/bin/sh: .../user_perl/lib/sun4-solaris/5.00401/perllocal.pod: cannot create
You can ignore it.

Press enter to continue.
__EOF__
my $dummy = <STDIN>;
