package IRC::Utils;
BEGIN {
  $IRC::Utils::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $IRC::Utils::VERSION = '0.12';
}

use strict;
use warnings FATAL => 'all';

use Encode qw(decode);
use Encode::Guess;

require Exporter;
use base qw(Exporter);
our @EXPORT_OK = qw(
    uc_irc lc_irc parse_mode_line normalize_mask matches_mask matches_mask_array
    unparse_mode_line gen_mode_change parse_user is_valid_nick_name eq_irc
    decode_irc is_valid_chan_name has_color has_formatting strip_color
    strip_formatting NORMAL BOLD UNDERLINE REVERSE ITALIC FIXED WHITE BLACK
    BLUE GREEN RED BROWN PURPLE ORANGE YELLOW LIGHT_GREEN TEAL LIGHT_CYAN
    LIGHT_BLUE PINK GREY LIGHT_GREY numeric_to_name name_to_numeric
);
our %EXPORT_TAGS = ( ALL => [@EXPORT_OK] );

use constant {
    # cancel all formatting and colors
    NORMAL      => "\x0f",

    # formatting
    BOLD        => "\x02",
    UNDERLINE   => "\x1f",
    REVERSE     => "\x16",
    ITALIC      => "\x1d",
    FIXED       => "\x11",
    BLINK       => "\x06",

    # mIRC colors
    WHITE       => "\x0300",
    BLACK       => "\x0301",
    BLUE        => "\x0302",
    GREEN       => "\x0303",
    RED         => "\x0304",
    BROWN       => "\x0305",
    PURPLE      => "\x0306",
    ORANGE      => "\x0307",
    YELLOW      => "\x0308",
    LIGHT_GREEN => "\x0309",
    TEAL        => "\x0310",
    LIGHT_CYAN  => "\x0311",
    LIGHT_BLUE  => "\x0312",
    PINK        => "\x0313",
    GREY        => "\x0314",
    LIGHT_GREY  => "\x0315",
};

# list originally snatched from AnyEvent::IRC::Util
our %NUMERIC2NAME = (
   '001' => 'RPL_WELCOME',           # RFC2812
   '002' => 'RPL_YOURHOST',          # RFC2812
   '003' => 'RPL_CREATED',           # RFC2812
   '004' => 'RPL_MYINFO',            # RFC2812
   '005' => 'RPL_ISUPPORT',          # draft-brocklesby-irc-isupport-03
   '008' => 'RPL_SNOMASK',           # Undernet
   '009' => 'RPL_STATMEMTOT',        # Undernet
   '010' => 'RPL_STATMEM',           # Undernet
   '020' => 'RPL_CONNECTING',        # IRCnet
   '014' => 'RPL_YOURCOOKIE',        # IRCnet
   '042' => 'RPL_YOURID',            # IRCnet
   '043' => 'RPL_SAVENICK',          # IRCnet
   '050' => 'RPL_ATTEMPTINGJUNC',    # aircd
   '051' => 'RPL_ATTEMPTINGREROUTE', # aircd
   '200' => 'RPL_TRACELINK',         # RFC1459
   '201' => 'RPL_TRACECONNECTING',   # RFC1459
   '202' => 'RPL_TRACEHANDSHAKE',    # RFC1459
   '203' => 'RPL_TRACEUNKNOWN',      # RFC1459
   '204' => 'RPL_TRACEOPERATOR',     # RFC1459
   '205' => 'RPL_TRACEUSER',         # RFC1459
   '206' => 'RPL_TRACESERVER',       # RFC1459
   '207' => 'RPL_TRACESERVICE',      # RFC2812
   '208' => 'RPL_TRACENEWTYPE',      # RFC1459
   '209' => 'RPL_TRACECLASS',        # RFC2812
   '210' => 'RPL_STATS',             # aircd
   '211' => 'RPL_STATSLINKINFO',     # RFC1459
   '212' => 'RPL_STATSCOMMANDS',     # RFC1459
   '213' => 'RPL_STATSCLINE',        # RFC1459
   '214' => 'RPL_STATSNLINE',        # RFC1459
   '215' => 'RPL_STATSILINE',        # RFC1459
   '216' => 'RPL_STATSKLINE',        # RFC1459
   '217' => 'RPL_STATSQLINE',        # RFC1459
   '218' => 'RPL_STATSYLINE',        # RFC1459
   '219' => 'RPL_ENDOFSTATS',        # RFC1459
   '221' => 'RPL_UMODEIS',           # RFC1459
   '231' => 'RPL_SERVICEINFO',       # RFC1459
   '233' => 'RPL_SERVICE',           # RFC1459
   '234' => 'RPL_SERVLIST',          # RFC1459
   '235' => 'RPL_SERVLISTEND',       # RFC1459
   '239' => 'RPL_STATSIAUTH',        # IRCnet
   '241' => 'RPL_STATSLLINE',        # RFC1459
   '242' => 'RPL_STATSUPTIME',       # RFC1459
   '243' => 'RPL_STATSOLINE',        # RFC1459
   '244' => 'RPL_STATSHLINE',        # RFC1459
   '245' => 'RPL_STATSSLINE',        # Bahamut, IRCnet, Hybrid
   '250' => 'RPL_STATSCONN',         # ircu, Unreal
   '251' => 'RPL_LUSERCLIENT',       # RFC1459
   '252' => 'RPL_LUSEROP',           # RFC1459
   '253' => 'RPL_LUSERUNKNOWN',      # RFC1459
   '254' => 'RPL_LUSERCHANNELS',     # RFC1459
   '255' => 'RPL_LUSERME',           # RFC1459
   '256' => 'RPL_ADMINME',           # RFC1459
   '257' => 'RPL_ADMINLOC1',         # RFC1459
   '258' => 'RPL_ADMINLOC2',         # RFC1459
   '259' => 'RPL_ADMINEMAIL',        # RFC1459
   '261' => 'RPL_TRACELOG',          # RFC1459
   '262' => 'RPL_TRACEEND',          # RFC2812
   '263' => 'RPL_TRYAGAIN',          # RFC2812
   '265' => 'RPL_LOCALUSERS',        # aircd, Bahamut, Hybrid
   '266' => 'RPL_GLOBALUSERS',       # aircd, Bahamut, Hybrid
   '267' => 'RPL_START_NETSTAT',     # aircd
   '268' => 'RPL_NETSTAT',           # aircd
   '269' => 'RPL_END_NETSTAT',       # aircd
   '270' => 'RPL_PRIVS',             # ircu
   '271' => 'RPL_SILELIST',          # ircu
   '272' => 'RPL_ENDOFSILELIST',     # ircu
   '300' => 'RPL_NONE',              # RFC1459
   '301' => 'RPL_AWAY',              # RFC1459
   '302' => 'RPL_USERHOST',          # RFC1459
   '303' => 'RPL_ISON',              # RFC1459
   '305' => 'RPL_UNAWAY',            # RFC1459
   '306' => 'RPL_NOWAWAY',           # RFC1459
   '307' => 'RPL_WHOISREGNICK',      # Bahamut, Unreal, Plexus
   '310' => 'RPL_WHOISMODES',        # Plexus
   '311' => 'RPL_WHOISUSER',         # RFC1459
   '312' => 'RPL_WHOISSERVER',       # RFC1459
   '313' => 'RPL_WHOISOPERATOR',     # RFC1459
   '314' => 'RPL_WHOWASUSER',        # RFC1459
   '315' => 'RPL_ENDOFWHO',          # RFC1459
   '317' => 'RPL_WHOISIDLE',         # RFC1459
   '318' => 'RPL_ENDOFWHOIS',        # RFC1459
   '319' => 'RPL_WHOISCHANNELS',     # RFC1459
   '321' => 'RPL_LISTSTART',         # RFC1459
   '322' => 'RPL_LIST',              # RFC1459
   '323' => 'RPL_LISTEND',           # RFC1459
   '324' => 'RPL_CHANNELMODEIS',     # RFC1459
   '325' => 'RPL_UNIQOPIS',          # RFC2812
   '328' => 'RPL_CHANNEL_URL',       # Bahamut, AustHex
   '329' => 'RPL_CREATIONTIME',      # Bahamut
   '330' => 'RPL_WHOISACCOUNT',      # ircu
   '331' => 'RPL_NOTOPIC',           # RFC1459
   '332' => 'RPL_TOPIC',             # RFC1459
   '333' => 'RPL_TOPICWHOTIME',      # ircu
   '338' => 'RPL_WHOISACTUALLY',     # Bahamut, ircu
   '340' => 'RPL_USERIP',            # ircu
   '341' => 'RPL_INVITING',          # RFC1459
   '342' => 'RPL_SUMMONING',         # RFC1459
   '345' => 'RPL_INVITED',           # GameSurge
   '346' => 'RPL_INVITELIST',        # RFC2812
   '347' => 'RPL_ENDOFINVITELIST',   # RFC2812
   '348' => 'RPL_EXCEPTLIST',        # RFC2812
   '349' => 'RPL_ENDOFEXCEPTLIST',   # RFC2812
   '351' => 'RPL_VERSION',           # RFC1459
   '352' => 'RPL_WHOREPLY',          # RFC1459
   '353' => 'RPL_NAMREPLY',          # RFC1459
   '354' => 'RPL_WHOSPCRPL',         # ircu
   '355' => 'RPL_NAMREPLY_',         # QuakeNet
   '361' => 'RPL_KILLDONE',          # RFC1459
   '362' => 'RPL_CLOSING',           # RFC1459
   '363' => 'RPL_CLOSEEND',          # RFC1459
   '364' => 'RPL_LINKS',             # RFC1459
   '365' => 'RPL_ENDOFLINKS',        # RFC1459
   '366' => 'RPL_ENDOFNAMES',        # RFC1459
   '367' => 'RPL_BANLIST',           # RFC1459
   '368' => 'RPL_ENDOFBANLIST',      # RFC1459
   '369' => 'RPL_ENDOFWHOWAS',       # RFC1459
   '371' => 'RPL_INFO',              # RFC1459
   '372' => 'RPL_MOTD',              # RFC1459
   '373' => 'RPL_INFOSTART',         # RFC1459
   '374' => 'RPL_ENDOFINFO',         # RFC1459
   '375' => 'RPL_MOTDSTART',         # RFC1459
   '376' => 'RPL_ENDOFMOTD',         # RFC1459
   '381' => 'RPL_YOUREOPER',         # RFC1459
   '382' => 'RPL_REHASHING',         # RFC1459
   '383' => 'RPL_YOURESERVICE',      # RFC2812
   '384' => 'RPL_MYPORTIS',          # RFC1459
   '385' => 'RPL_NOTOPERANYMORE',    # AustHex, Hybrid, Unreal
   '391' => 'RPL_TIME',              # RFC1459
   '392' => 'RPL_USERSSTART',        # RFC1459
   '393' => 'RPL_USERS',             # RFC1459
   '394' => 'RPL_ENDOFUSERS',        # RFC1459
   '395' => 'RPL_NOUSERS',           # RFC1459
   '396' => 'RPL_HOSTHIDDEN',        # Undernet
   '401' => 'ERR_NOSUCHNICK',        # RFC1459
   '402' => 'ERR_NOSUCHSERVER',      # RFC1459
   '403' => 'ERR_NOSUCHCHANNEL',     # RFC1459
   '404' => 'ERR_CANNOTSENDTOCHAN',  # RFC1459
   '405' => 'ERR_TOOMANYCHANNELS',   # RFC1459
   '406' => 'ERR_WASNOSUCHNICK',     # RFC1459
   '407' => 'ERR_TOOMANYTARGETS',    # RFC1459
   '408' => 'ERR_NOSUCHSERVICE',     # RFC2812
   '409' => 'ERR_NOORIGIN',          # RFC1459
   '411' => 'ERR_NORECIPIENT',       # RFC1459
   '412' => 'ERR_NOTEXTTOSEND',      # RFC1459
   '413' => 'ERR_NOTOPLEVEL',        # RFC1459
   '414' => 'ERR_WILDTOPLEVEL',      # RFC1459
   '415' => 'ERR_BADMASK',           # RFC2812
   '421' => 'ERR_UNKNOWNCOMMAND',    # RFC1459
   '422' => 'ERR_NOMOTD',            # RFC1459
   '423' => 'ERR_NOADMININFO',       # RFC1459
   '424' => 'ERR_FILEERROR',         # RFC1459
   '425' => 'ERR_NOOPERMOTD',        # Unreal
   '429' => 'ERR_TOOMANYAWAY',       # Bahamut
   '430' => 'ERR_EVENTNICKCHANGE',   # AustHex
   '431' => 'ERR_NONICKNAMEGIVEN',   # RFC1459
   '432' => 'ERR_ERRONEUSNICKNAME',  # RFC1459
   '433' => 'ERR_NICKNAMEINUSE',     # RFC1459
   '436' => 'ERR_NICKCOLLISION',     # RFC1459
   '439' => 'ERR_TARGETTOOFAST',     # ircu
   '440' => 'ERR_SERCVICESDOWN',     # Bahamut, Unreal
   '441' => 'ERR_USERNOTINCHANNEL',  # RFC1459
   '442' => 'ERR_NOTONCHANNEL',      # RFC1459
   '443' => 'ERR_USERONCHANNEL',     # RFC1459
   '444' => 'ERR_NOLOGIN',           # RFC1459
   '445' => 'ERR_SUMMONDISABLED',    # RFC1459
   '446' => 'ERR_USERSDISABLED',     # RFC1459
   '447' => 'ERR_NONICKCHANGE',      # Unreal
   '449' => 'ERR_NOTIMPLEMENTED',    # Undernet
   '451' => 'ERR_NOTREGISTERED',     # RFC1459
   '455' => 'ERR_HOSTILENAME',       # Unreal
   '459' => 'ERR_NOHIDING',          # Unreal
   '460' => 'ERR_NOTFORHALFOPS',     # Unreal
   '461' => 'ERR_NEEDMOREPARAMS',    # RFC1459
   '462' => 'ERR_ALREADYREGISTRED',  # RFC1459
   '463' => 'ERR_NOPERMFORHOST',     # RFC1459
   '464' => 'ERR_PASSWDMISMATCH',    # RFC1459
   '465' => 'ERR_YOUREBANNEDCREEP',  # RFC1459
   '466' => 'ERR_YOUWILLBEBANNED',   # RFC1459
   '467' => 'ERR_KEYSET',            # RFC1459
   '469' => 'ERR_LINKSET',           # Unreal
   '471' => 'ERR_CHANNELISFULL',     # RFC1459
   '472' => 'ERR_UNKNOWNMODE',       # RFC1459
   '473' => 'ERR_INVITEONLYCHAN',    # RFC1459
   '474' => 'ERR_BANNEDFROMCHAN',    # RFC1459
   '475' => 'ERR_BADCHANNELKEY',     # RFC1459
   '476' => 'ERR_BADCHANMASK',       # RFC2812
   '477' => 'ERR_NOCHANMODES',       # RFC2812
   '478' => 'ERR_BANLISTFULL',       # RFC2812
   '481' => 'ERR_NOPRIVILEGES',      # RFC1459
   '482' => 'ERR_CHANOPRIVSNEEDED',  # RFC1459
   '483' => 'ERR_CANTKILLSERVER',    # RFC1459
   '484' => 'ERR_RESTRICTED',        # RFC2812
   '485' => 'ERR_UNIQOPPRIVSNEEDED', # RFC2812
   '488' => 'ERR_TSLESSCHAN',        # IRCnet
   '491' => 'ERR_NOOPERHOST',        # RFC1459
   '492' => 'ERR_NOSERVICEHOST',     # RFC1459
   '493' => 'ERR_NOFEATURE',         # ircu
   '494' => 'ERR_BADFEATURE',        # ircu
   '495' => 'ERR_BADLOGTYPE',        # ircu
   '496' => 'ERR_BADLOGSYS',         # ircu
   '497' => 'ERR_BADLOGVALUE',       # ircu
   '498' => 'ERR_ISOPERLCHAN',       # ircu
   '501' => 'ERR_UMODEUNKNOWNFLAG',  # RFC1459
   '502' => 'ERR_USERSDONTMATCH',    # RFC1459
   '503' => 'ERR_GHOSTEDCLIENT',     # Hybrid
);

our %NAME2NUMERIC;
while (my ($key, $val) = each %NUMERIC2NAME) {
    $NAME2NUMERIC{$val} = $key;
}

sub numeric_to_name {
   my ($code) = @_;
   return $NUMERIC2NAME{$code};
}

sub name_to_numeric {
   my ($name) = @_;
   return $NAME2NUMERIC{$name};
}

sub uc_irc {
    my ($value, $type) = @_;
    return if !defined $value;
    $type = 'rfc1459' if !defined $type;
    $type = lc $type;

    if ($type eq 'ascii') {
        $value =~ tr/a-z/A-Z/;
    }
    elsif ($type eq 'strict-rfc1459') {
        $value =~ tr/a-z{}|/A-Z[]\\/;
    }
    else {
        $value =~ tr/a-z{}|^/A-Z[]\\~/;
    }

    return $value;
}

sub lc_irc {
    my ($value, $type) = @_;
    return if !defined $value;
    $type = 'rfc1459' if !defined $type;
    $type = lc $type;

    if ($type eq 'ascii') {
        $value =~ tr/A-Z/a-z/;
    }
    elsif ($type eq 'strict-rfc1459') {
        $value =~ tr/A-Z[]\\/a-z{}|/;
    }
    else {
        $value =~ tr/A-Z[]\\~/a-z{}|^/;
    }

    return $value;
}

sub eq_irc {
    my ($first, $second, $type) = @_;
    return if !defined $first || !defined $second;
    return 1 if lc_irc($first, $type) eq lc_irc($second, $type);
    return;
}

sub parse_mode_line {
    my @args = @_;

    my $chanmodes = [qw(beI k l imnpstaqr)];
    my $statmodes = 'ohv';
    my $hashref = { };
    my $count = 0;

    while (my $arg = shift @args) {
        if ( ref $arg eq 'ARRAY' ) {
           $chanmodes = $arg;
           next;
        }
        elsif (ref $arg eq 'HASH') {
           $statmodes = join '', keys %{ $arg };
           next;
        }
        elsif ($arg =~ /^[-+]/ or $count == 0) {
            my $action = '+';
            for my $char (split //, $arg) {
                if ($char eq '+' or $char eq '-') {
                   $action = $char;
                }
                else {
                   push @{ $hashref->{modes} }, $action . $char;
                }

                if (length $chanmodes->[0] && length $chanmodes->[1] && length $statmodes
                    && $char =~ /[$statmodes$chanmodes->[0]$chanmodes->[1]]/) {
                    push @{ $hashref->{args} }, shift @args;
                }

                if (length $chanmodes->[2] && $action eq '+' && $char =~ /[$chanmodes->[2]]/) {
                    push @{ $hashref->{args} }, shift @args;
                }
            }
        }
        else {
            push @{ $hashref->{args} }, $arg;
        }
        $count++;
    }

    return $hashref;
}

sub normalize_mask {
    my ($arg) = @_;
    return if !defined $arg;

    $arg =~ s/\*{2,}/*/g;
    my @mask;
    my $remainder;
    if ($arg !~ /!/ and $arg =~ /@/) {
        $remainder = $arg;
        $mask[0] = '*';
    }
    else {
        ($mask[0], $remainder) = split /!/, $arg, 2;
    }

    $remainder =~ s/!//g if defined $remainder;
    @mask[1..2] = split(/@/, $remainder, 2) if defined $remainder;
    $mask[2] =~ s/@//g if defined $mask[2];

    for my $i (1..2) {
        $mask[$i] = '*' if !defined $mask[$i];
    }
    return $mask[0] . '!' . $mask[1] . '@' . $mask[2];
}

sub unparse_mode_line {
    my ($line) = @_;
    return if !defined $line || !length $line;

    my $action; my $return;
    for my $mode ( split(//,$line) ) {
       if ($mode =~ /^(\+|-)$/ && (!$action || $mode ne $action)) {
         $return .= $mode;
         $action = $mode;
         next;
       }
       $return .= $mode if ($mode ne '+' and $mode ne '-');
    }
    $return =~ s/[+-]$//;
    return $return;
}

sub gen_mode_change {
    my ($before, $after) = @_;
    $before = '' if !defined $before;
    $after = '' if !defined $after;

    my @before = split //, $before;
    my @after  = split //, $after;
    my $string = '';
    my @hunks = _diff(\@before, \@after);
    $string .= $_->[0] . $_->[1] for @hunks;

    return unparse_mode_line($string);
}

sub is_valid_nick_name {
    my ($nickname) = @_;
    return if !defined $nickname || !length $nickname;
    return 1 if $nickname =~ /^[A-Za-z_`\-^\|\\\{}\[\]][A-Za-z_0-9`\-^\|\\\{}\[\]]*$/;
    return;
}

sub is_valid_chan_name {
    my $channel = shift;
    my $chantypes = shift || ['#', '&'];
    return if !@$chantypes;
    my $chanprefix = join '', @$chantypes;
    return if !defined $channel || !length $channel;

    return if bytes::length($channel) > 200;
    return 1 if $channel =~ /^[$chanprefix][^ \a\0\012\015,:]+$/;
    return;
}

sub matches_mask_array {
    my ($masks, $matches, $mapping) = @_;

    return if !defined $masks || !defined $matches;
    return if ref $masks ne 'ARRAY';
    return if ref $matches ne 'ARRAY';
    my $ref = { };

    for my $mask (@$masks) {
        for my $match (@$matches) {
            if (matches_mask($mask, $match, $mapping)) {
                push @{ $ref->{ $mask } }, $match;
            }
        }
    }

    return $ref;
}

sub matches_mask {
    my ($mask, $match, $mapping) = @_;
    return if !defined $mask || !length $mask;
    return if !defined $match || !length $match;

    my $umask = quotemeta uc_irc($mask, $mapping);
    $umask =~ s/\\\*/[\x01-\xFF]{0,}/g;
    $umask =~ s/\\\?/[\x01-\xFF]{1,1}/g;
    $match = uc_irc($match, $mapping);

    return 1 if $match =~ /^$umask$/;
    return;
}

sub parse_user {
    my ($user) = @_;
    return if !defined $user;

    my ($n, $u, $h) = split /[!@]/, $user;
    return ($n, $u, $h) if wantarray();
    return $n;
}

sub has_color {
    my ($string) = @_;
    return if !defined $string;
    return 1 if $string =~ /[\x03\x04\x1B]/;
    return;
}

sub has_formatting {
    my ($string) = @_;
    return if !defined $string;
    return 1 if $string =~/[\x02\x1f\x16\x1d\x11\x06]/;
    return;
}

sub strip_color {
    my ($string) = @_;
    return if !defined $string;

    # mIRC colors
    $string =~ s/\x03(?:,\d{1,2}|\d{1,2}(?:,\d{1,2})?)?//g;

    # RGB colors supported by some clients
    $string =~ s/\x04[0-9a-fA-F]{0,6}//ig;

    # see ECMA-48 + advice by urxvt author
    $string =~ s/\x1B\[.*?[\x00-\x1F\x40-\x7E]//g;

    # strip cancellation codes too if there are no formatting codes
    $string =~ s/\x0f//g if !has_formatting($string);
    return $string;
}

sub strip_formatting {
    my ($string) = @_;
    return if !defined $string;
    $string =~ s/[\x02\x1f\x16\x1d\x11\x06]//g;

    # strip cancellation codes too if there are no color codes
    $string =~ s/\x0f//g if !has_color($string);

    return $string;
}

sub decode_irc {
    my ($line) = @_;
    my $utf8 = guess_encoding($line, 'utf8');
    return ref $utf8 ? decode('utf8', $line) : decode('cp1252', $line);
}

sub _diff {
    my ($before, $after) = @_;
    my %in_before;
    @in_before{@$before} = ();
    my %in_after;
    @in_after{@$after} = ();
    my (@diff, %seen);

    for my $seen (@$before) {
        next if exists $seen{$seen} || exists $in_after{$seen};
        $seen{$seen} = 1;
        push @diff, ['-', $seen];
    }

    %seen = ();

    for my $seen (@$after) {
        next if exists $seen{$seen} || exists $in_before{$seen};
        $seen{$seen} = 1;
        push @diff, ['+', $seen];
    }

    return @diff;
}

1;

=encoding utf8

=head1 NAME

IRC::Utils - Common utilities for IRC-related tasks

=head1 SYNOPSIS

 use strict;
 use warnings;

 use IRC::Utils ':ALL';

 my $nickname = '^Lame|BOT[moo]';
 my $uppercase_nick = uc_irc($nickname);
 my $lowercase_nick = lc_irc($nickname);

 print "They're equivalent\n" if eq_irc($uppercase_nick, $lowercase_nick);

 my $mode_line = 'ov+b-i Bob sue stalin*!*@*';
 my $hashref = parse_mode_line($mode_line);

 my $banmask = 'stalin*';
 my $full_banmask = normalize_mask($banmask);

 if (matches_mask($full_banmask, 'stalin!joe@kremlin.ru')) {
     print "EEK!";
 }

 my $decoded = irc_decode($raw_irc_message);
 print $decoded, "\n";

 if (has_color($message)) {
    print 'COLOR CODE ALERT!\n";
 }

 my $results_hashref = matches_mask_array(\@masks, \@items_to_match_against);

 my $nick = parse_user('stalin!joe@kremlin.ru');
 my ($nick, $user, $host) = parse_user('stalin!joe@kremlin.ru');

=head1 DESCRIPTION

The functions in this module take care of many of the tasks you are faced
with when working with IRC. Mode lines, ban masks, message encoding and
formatting, etc.

=head1 FUNCTIONS

=head2 C<uc_irc>

Takes one mandatory parameter, a string to convert to IRC uppercase, and one
optional parameter, the casemapping of the ircd (which can be B<'rfc1459'>,
B<'strict-rfc1459'> or B<'ascii'>. Default is B<'rfc1459'>). Returns the IRC
uppercase equivalent of the passed string.

=head2 C<lc_irc>

Takes one mandatory parameter, a string to convert to IRC lowercase, and one
optional parameter, the casemapping of the ircd (which can be B<'rfc1459'>,
B<'strict-rfc1459'> or B<'ascii'>. Default is B<'rfc1459'>). Returns the IRC
lowercase equivalent of the passed string.

=head2 C<eq_irc>

Takes two mandatory parameters, IRC strings (channels or nicknames) to
compare. A third, optional parameter specifies the casemapping. Returns true
if the two strings are equivalent, false otherwise

 # long version
 lc_irc($one, $map) eq lc_irc($two, $map)

 # short version
 eq_irc($one, $two, $map)

=head2 C<parse_mode_line>

Takes a list representing an IRC mode line. Returns a hashref. Optionally
you can also supply an arrayref and a hashref to specify valid channel
modes (default: C<[qw(beI k l imnpstaqr)]>) and status modes (default:
C<< {o => '@', h => '%', v => '+'} >>), respectively.

If the modeline
couldn't be parsed the hashref will be empty. On success the following keys
will be available in the hashref:

B<'modes'>, an arrayref of normalised modes;

B<'args'>, an arrayref of applicable arguments to the modes;

Example:

 my $hashref = parse_mode_line( 'ov+b-i', 'Bob', 'sue', 'stalin*!*@*' );

 # $hashref will be:
 {
    modes => [ '+o', '+v', '+b', '-i' ],
    args  => [ 'Bob', 'sue', 'stalin*!*@*' ],
 }

=head2 C<normalize_mask>

Takes one parameter, a string representing an IRC mask. Returns a normalised
full mask.

Example:

 $fullbanmask = normalize_mask( 'stalin*' );

 # $fullbanmask will be: 'stalin*!*@*';

=head2 C<matches_mask>

Takes two parameters, a string representing an IRC mask and something to
match against the IRC mask, such as a nick!user@hostname string. Returns
a true value if they match, a false value otherwise. Optionally, one may
pass the casemapping (see L<C<uc_irc>|/uc_irc>), as this function uses
C<uc_irc> internally.

=head2 C<matches_mask_array>

Takes two array references, the first being a list of strings representing
IRC masks, the second a list of somethings to test against the masks. Returns
an empty hashref if there are no matches. Otherwise, the keys will be the
masks matched, each value being an arrayref of the strings that matched it.
Optionally, one may pass the casemapping (see L<C<uc_irc>|/uc_irc>), as
this function uses C<uc_irc> internally.

=head2 C<unparse_mode_line>

Takes one argument, a string representing a number of mode changes. Returns
a condensed version of the changes.

  my $mode_line = unparse_mode_line('+o+o+o-v+v');
  $mode_line is now '+ooo-v+v'

=head2 C<gen_mode_change>

Takes two arguments, strings representing a set of IRC user modes before and
after a change. Returns a string representing what changed.

  my $mode_change = gen_mode_change('abcde', 'befmZ');
  $mode_change is now '-acd+fmZ'

=head2 C<parse_user>

Takes one parameter, a string representing a user in the form
nick!user@hostname. In a scalar context it returns just the nickname.
In a list context it returns a list consisting of the nick, user and hostname,
respectively.

=head2 C<is_valid_chan_name>

Takes one argument, a channel name to validate. Returns true or false if the
channel name is valid or not. You can supply a second argument, an array of
characters of allowed channel prefixes. Defaults to C<['#', '&']>.

=head2 C<is_valid_nick_name>

Takes one argument, a nickname to validate. Returns true or false if the
nickname is valid or not.

=head2 C<numeric_to_name>

Takes an IRC server numerical reply code (e.g. '001') as an argument, and
returns the corresponding name (e.g. 'RPL_WELCOME').

=head2 C<name_to_numeric>

Takes an IRC server reply name (e.g. 'RPL_WELCOME') as an argument, and returns the
corresponding numerical code (e.g. '001').

=head2 C<has_color>

Takes one parameter, a string of IRC text. Returns true if it contains any IRC
color codes, false otherwise. Useful if you want your bot to kick users for
(ab)using colors. :)

=head2 C<has_formatting>

Takes one parameter, a string of IRC text. Returns true if it contains any IRC
formatting codes, false otherwise.

=head2 C<strip_color>

Takes one parameter, a string of IRC text. Returns the string stripped of all
IRC color codes.

=head2 C<strip_formatting>

Takes one parameter, a string of IRC text. Returns the string stripped of all
IRC formatting codes.

=head2 C<decode_irc>

This function takes a byte string (i.e. an unmodified IRC message) and
returns a text string. Since the source encoding might have been UTF-8,
you should store it with UTF-8 or some other Unicode encoding in your
file/database/whatever to be safe. For a more detailed discussion, see
L</ENCODING>.

 use IRC::Utils qw(decode_irc);

 sub message_handler {
     my ($nick, $channel, $message) = @_;

     # not wise, $message is a byte string of unkown encoding
     print $message, "\n";

     $message = decode_irc($what);

     # good, $message is a text string
     print $message, "\n";
 }

=head1 CONSTANTS

Use the following constants to add formatting and mIRC color codes to IRC
messages.

Normal text:

 NORMAL

Formatting:

 BOLD
 UNDERLINE
 REVERSE
 ITALIC
 FIXED

Colors:

 WHITE
 BLACK
 BLUE
 GREEN
 RED
 BROWN
 PURPLE
 ORANGE
 YELLOW
 LIGHT_GREEN
 TEAL
 LIGHT_CYAN
 LIGHT_BLUE
 PINK
 GREY
 LIGHT_GREY

Individual non-color formatting codes can be cancelled with their
corresponding constant, but you can also cancel all of them at once with
C<NORMAL>. To cancel the effect of color codes, you must use C<NORMAL>.
which of course has the side effect of cancelling all other formatting codes
as well.

 $msg = 'This word is '.YELLOW.'yellow'.NORMAL.' while this word is'.BOLD.'bold'.BOLD;
 $msg = UNDERLINE.BOLD.'This sentence is both underlined and bold.'.NORMAL;

=head1 ENCODING

=head2 Messages

The only encoding requirement the IRC protocol places on its messages is
that they be 8-bits and ASCII-compatible. This has resulted in most of the
Western world settling on ASCII-compatible Latin-1 (usually Microsoft's
CP1252, a Latin-1 variant) as a convention. Recently, popular IRC clients
(mIRC, xchat, certain irssi configurations) have begun sending a mixture of
CP1252 and UTF-8 over the wire to allow more characters without breaking
backward compatibility (too much). They send CP1252 encoded messages if the
characters fit within that encoding, otherwise falling back to UTF-8, and
likewise autodetecting the encoding (UTF-8 or CP1252) of incoming messages.
Since writing text with mixed encoding to a file, terminal, or database is
not a good idea, you need a way to decode messages from IRC.
L<C<decode_irc>|/decode_irc> will do that.

=head2 Channel names

The matter is complicated further by the fact that some servers allow
non-ASCII characters in channel names. IRC modules generally don't
explicitly encode or decode any IRC traffic, but they do have to
concatenate parts of a message (e.g. a channel name and a message) before
sending it over the wire. So when you do something like
C<< privmsg($channel, 'æði') >>, where C<$channel> is the unmodified
channel name (a byte string) you got from an earlier IRC message, the
channel name will get double-encoded when concatenated with your message (a
non-ASCII text string) if the channel name contains non-ASCII bytes.

To prevent this, you can't simply L<decode|/decode_irc> the channel name and
then use it. C<'#æði'> in CP1252 is not the same channel as C<'#æði'> in
UTF-8, since they are encoded as different sequences of bytes, and the IRC
server only cares about the byte representation. Therefore, when using a
channel name you got from the server (e.g. when replying to message), you
should use the original byte string (before it has been decoded with
L<C<decode_irc>|/decode_irc>), and encode any other parameters (with
L<C<encode_utf8>|Encode>) so that your message will be concatenated
correctly. At some point, you'll probably want to print the channel name,
write it to a log file or use it in a filename, so you'll eventually have to
decode it, at which point the UTF-8 C<#æði> and CP1252 C<#æði> will have to
be considered equivalent.

 use Encode qw(encode_utf8 encode);

 sub message_handler {
     # these three are all byte strings
     my ($nick, $channel, $message) = @_;

     # bad: if $channel has any non-ASCII bytes, they will get double-encoded
     privmsg($channel, 'æði');

     # bad: if $message has any non-ASCII bytes, they will get double-encoded
     privmsg('#æði', $message);

     # good: both are byte strings already, so they will concatenate correctly
     privmsg($channel, $message);

     # good: both are text strings (Latin1 as per Perl's default), so
     # they'll be concatenated correctly
     privmsg('#æði', 'æði');

     # good: similar to the last one, except now they're using UTF-8, which
     # means that the channel is actually not the same as above
     use utf8;
     privmsg('#æði', 'æði');

     # good: $channel and $msg_bytes are both byte strings
     my $msg_bytes = encode_utf8('æði');
     privmsg($channel, $msg_bytes);

     # good: $chan_bytes and $message are both byte strings
     # here we're sending a message to the utf8-encoded #æði
     my $utf8_bytes = encode_utf8('#æði');
     privmsg($utf8_bytes, $message);

     # good: $chan_bytes and $message are both byte strings
     # here we're sending a message to the cp1252-encoded #æði
     my $cp1252_bytes = encode('cp1252', '#æði');
     privmsg($cp1252_bytes, $message);

     # bad: $channel is in an undetermined encoding
     log_message("Got message from $channel");

     # good: using the decoded version of $channel
     log_message("Got message from ".decode_irc($channel));
 }

See also L<Encode|Encode>, L<perluniintro|perluniintro>,
L<perlunitut|perlunitut>, L<perlunicode|perlunicode>, and
L<perlunifaq|perlunifaq>.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson <hinrik.sig@gmail.com> (C<Hinrik> irc.perl.org, or C<literal> @ FreeNode).

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 SEE ALSO

L<POE::Component::IRC|POE::Component::IRC>

L<POE::Component::Server::IRC|POE::Component::Server::IRC>

=cut
