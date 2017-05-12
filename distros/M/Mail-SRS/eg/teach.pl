use strict;
use Mail::SRS;

my $srs = new Mail::SRS(
				Secret	=> "foo",	# Please, PLEASE change this!
					);

# A mail from a@source.com goes to b@forwarder.com and gets forwarded
# to c@target.com.

my $source = "a\@source.com";
my $alias = "b\@forward.com";
my $target = "c\@target.com";
my $final = "d\@final.com";

my $srsdb = "/tmp/srs-eg.db";

sub presskey {
	print "\nPress <enter> ==================================\n";
	<>;
	print "\n" x 6;
}

print << "EOM";

Imagine a mail:
	$source --> $alias
The return path of the mail is originally $source.

Imagine a redirector:
	$alias REDIRECTS TO $target

If $alias resends the mail with return path $source,
SPF at $target will reject it, so we must rewrite the return
path so that it comes from the domain of $alias.

EOM

my $newsource = $srs->forward($source, $alias);

print << "EOM";
So when $alias forwards the mail, it rewrites the return path
according to SRS, to get:
	$newsource

This is what the \$srs->forward() method does.
EOM

presskey;

print << "EOM";
If the mail bounces, the mail goes back to the forwarder, which
applies the reverse transformation to get:
EOM

my $oldsource = $srs->reverse($newsource);

print << "EOM";
	$oldsource

This is what the \$srs->reverse() method does.

The extra fields in the funny-looking address encode the timestamp when
the forwards transformation was performed and a cryptographic hash. The
timestamp ensures that we don't forward bounces back ad infinitum,
but only for (say) one month. The cryptographic hash ensures that
SRS addresses for a particular host cannot be forged. When
$alias gets a returned mail, it can check the hash with its
secret data to make sure this is a real SRS address.
EOM

presskey;

my $srs1source = $srs->forward($newsource, $target);

print << "EOM";
If $target is in fact a forwarder, sending to $final,
then $target must rewrite the sender again. Bounces must be
cryptographically checked before they are sent to a real person,
therefore the first SRS link in the chain is maintained, and the
address becomes
	$srs1source

This new sender does not contain any new cryptographic information. It
contains only the original cryptographic hash from $alias
and it assumes that $alias will check its own hash before
returning the mail to $source.
EOM

presskey;

my $srs1source1 = $srs->forward($srs1source, $final);
my $srs0source = $srs->reverse($srs1source);
my $reverse = $srs->reverse($srs0source);

print << "EOM";
Now, when either $final or $target performs the reverse
transformation, it will get the original SRS address for bounces:
	$srs0source

And then the first forwarder in the chain may perform a final reversal,
checking the cryptographic information before returning the mail to
	$reverse

If the mail was to be forwarded a third time, hops can be dropped on the
return path, and the new SRS1 address would be
	$srs1source1

For more information on the peculiarities of this `second layer', see
the web page at http://www.anarres.org/projects/srs/
EOM

presskey;

use Mail::SRS::Shortcut;
$srs = new Mail::SRS::Shortcut(
				Secret	=> "foo",
					);
my $srs0a = $srs->forward($source, $alias);
my $srs0b = $srs->forward($srs0a, $target);
my $orig = $srs->reverse($srs0b);

print << "EOM";
This code provides for three other possible types of transformation.
The first is a simplistic SRS scheme which implements only a part of
the SRS scheme. It shortcuts even the first forwarder after the
source address, so the rewriting sequence would proceed as follows:

	$source
via a forwarder becomes
	$srs0a
which if forwarded again, becomes simply
	$srs0b
which when reversed, returns to
	$orig

WARNING: IF YOU USE THIS SIMPLE SYSTEM, YOU MAY BECOME AN OPEN RELAY

EOM

presskey;

use Mail::SRS::Reversible;
$srs = new Mail::SRS::Reversible(
				Secret	=> "foo",
					);
my $revsource = $srs->forward($newsource, $final);

print << "EOM";
The second is the fully reversable transformation, and is provided by a
subclass of Mail::SRS called Mail::SRS::Reversible. This subclass
rewrites
	$newsource
to
	$revsource

This is excessively long and breaks the 64 character limit required
by RFC821 and RFC2821. This package is provided for randomness and
completeness, and its use is NOT RECOMMENDED.

The next test will write to a file called $srsdb

Abort now if this file is not writable, or you do not want this script
to write to that file.
EOM

presskey;

use Mail::SRS::DB;
$srs = new Mail::SRS::DB(
				Secret		=> "foo",
				Database	=> $srsdb,
					);
my $dbsource = $srs->forward($source, $final);
my $dbrev = $srs->reverse($dbsource);
$srs = undef;	# garb!
unlink($srsdb);

print << "EOM";
The last mechanism provided by this code is a database driven system.
This is designed to be useful to people requiring more functionality
from a custom sender rewriting scheme.

In this case, the address
	$source
is rewritten to
	$dbsource
and any bounces will be looked up in the database to retrieve
	$dbrev
The new address $dbsource is also cryptographic,
and is used as a database key to find the original address and any
timeout or reuse information. The source of Mail::SRS::DB provides
a good example for people wanting to build more complex rewriting
schemes.

IMPORTANT: While the database mechanism provides the same functionality
as SRS, the new return path is NOT an SRS address, and therefore does
NOT start with "SRS+". This is so that database rewriting schemes and
`true' SRS schemes can operate seamlessly on the `same' internet.
EOM

presskey;

print << "EOM";
Now go and read the web page at http://www.anarres.org/projects/srs/

If your questions are not answered there, then please mail the
maintainers.
EOM
