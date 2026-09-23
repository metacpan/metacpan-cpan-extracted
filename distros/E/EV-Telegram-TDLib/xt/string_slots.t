use strict;
use warnings;
use Test::More;
use File::Spec;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# A TL string slot filled by interpolating a caller's value sends
# "HASH(0x55...)" when that value is a reference -- a formattedText from
# translate(), the chatInviteLink that invite_link() just returned, the
# stickerSet from sticker_set(). Telegram accepts the string, so nothing
# fails: an album really is named HASH(0x...), and a search for one quietly
# matches nothing. plain_text() croaks on such a ref and stringifies an
# object that overloads "", so every caller-supplied string slot goes
# through it.
#
# The existing checks test the slots that were fixed, one entry per fix,
# so they can only ever confirm yesterday's sweep. This one fails on a new
# site the moment it is written.

my @files = (
    'lib/EV/Telegram/TDLib.pm',
    glob('lib/EV/Telegram/TDLib/*.pm'),
);

# The four places where interpolating is right, each because the value is
# already known not to be a stray reference.
my @allowed = (
    [ 'Chats.pm',    '"$type:"',            'a cache key, not a request slot' ],
    [ 'Messages.pm', '$text = defined',     'format_text rejects a ref above' ],
    [ 'TDLib.pm',    'return defined $v',   'this is plain_text itself' ],
    [ 'TDLib.pm',    "'\@extra' => \"\$extra\"", 'the module\'s own counter' ],
    [ 'TDLib.pm',    'my $s = "$why"',      'stringifying an error to report' ],
    [ 'TDLib.pm',    'my $s = "$err"',      'stringifying an error to report' ],
);

my @bad;
for my $file (@files) {
    next if $file =~ /Schema\.pm$/;   # generated tables, no caller values
    open my $fh, '<', $file or die "$file: $!";
    my ($base) = $file =~ m{([^/]+)$};
    while (my $line = <$fh>) {
        next unless $line =~ /=> *"\$/ || $line =~ /\? *"\$/
                 || $line =~ /= *"\$/   || $line =~ /"" *\. *\(/
                 || $line =~ /"\$_"/;
        next if grep { $_->[0] eq $base && index($line, $_->[1]) >= 0 } @allowed;
        chomp $line;
        $line =~ s/\A\s+//;
        push @bad, "$file:$.: $line";
    }
    close $fh;
}

is scalar @bad, 0, 'every caller-supplied string slot goes through plain_text'
    or diag "use plain_text('a thing', \$value) instead:\n  " . join "\n  ", @bad;

# and the helper really does refuse a ref, so the check above means something
require EV;
require EV::Telegram::TDLib;
my $ft = { '@type' => 'formattedText', text => 'x', entities => [] };
my $err = do { local $@; eval { EV::Telegram::TDLib::plain_text('a thing', $ft); 1 }
                   ? '' : $@ };
like $err, qr/a thing must be a string/, 'plain_text refuses a formattedText';

my $obj = bless {}, 'XT::Stringy';
{ no strict 'refs'; *{'XT::Stringy::(""'} = sub { 'as a string' };
  *{'XT::Stringy::()'} = sub {}; ${'XT::Stringy::()'} = 0; }
is EV::Telegram::TDLib::plain_text('a thing', $obj), 'as a string',
    'but takes an object that stringifies';

done_testing;
