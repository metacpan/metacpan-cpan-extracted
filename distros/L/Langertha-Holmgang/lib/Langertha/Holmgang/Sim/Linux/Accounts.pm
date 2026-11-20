package Langertha::Holmgang::Sim::Linux::Accounts;
# ABSTRACT: Accounts and sudo on a simulated Linux server — passwd, chage, deluser, userdel, visudo, sudo -l

use strict;
use warnings;
use utf8;

use JSON::MaybeXS ();
use Time::Local ();

our $VERSION = '0.002';


sub _today { return int( Time::Local::timegm( 0, 0, 12, 20, 9, 2026 ) / 86400 ) }

sub _days {
    my ($v) = @_;
    return undef if !defined $v || $v eq '' || $v eq '-1';
    return 0 + $v if $v =~ /\A\d+\z/;
    my ( $y, $m, $d ) = $v =~ /\A(\d{4})-(\d{2})-(\d{2})\z/ or return 'bad';
    return int( Time::Local::timegm( 0, 0, 12, $d, $m - 1, $y ) / 86400 );
}

sub _date {
    my ($days) = @_;
    my @t = gmtime( $days * 86400 );
    return sprintf '%s %02d, %04d', (qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ))[ $t[4] ], $t[3], $t[5] + 1900;    # wie chage -l
}


sub set_expire {
    my ( $dev, $e, $v ) = @_;
    my $d = _days($v);
    return "invalid date '$v'" if defined $d && $d eq 'bad';
    if ( defined $d ) {
        $e->{expire} = $d unless defined $e->{expire} && $e->{expire} == $d;
        if   ( $d <= _today() ) { $e->{expired} = JSON::MaybeXS::true() unless $e->{expired} }
        else                    { delete $e->{expired} }
    }
    else {
        delete $e->{expire};
        delete $e->{expired};
    }
    return undef;
}

sub _user { my ( $dev, $u ) = @_; return ( $dev->{users} || {} )->{ $u // '' } }


sub passwd {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my %o;
    while ( @a && $a[0] =~ /\A-/ ) { my $x = shift @a; $o{$_} = 1 for split //, substr( $x, 1 ) }
    my $u = shift @a;
    return ( 'passwd: You may not view or modify password information for root.', 0 ) if !defined $u && !%o;
    my $e = _user( $dev, $u ) or return ( "passwd: user '" . ( $u // '' ) . "' does not exist", 0 );
    if ( $o{S} ) { return ( sprintf( '%s %s 10/20/2026 0 99999 7 -1', $u, $e->{locked} ? 'L' : 'P' ), 1 ) }
    if ( $o{l} ) { $e->{locked} = JSON::MaybeXS::true() unless $e->{locked}; return ( 'passwd: password changed.', 1 ) }
    if ( $o{u} ) { $e->{locked} = JSON::MaybeXS::false() if $e->{locked}; return ( 'passwd: password changed.', 1 ) }
    if ( $o{e} ) { return ( 'passwd: password changed.', 1 ) }
    if ( $o{d} ) { $e->{locked} = JSON::MaybeXS::false() if $e->{locked}; $e->{no_password} = JSON::MaybeXS::true(); return ( 'passwd: password changed.', 1 ) }
    return ( 'passwd: Authentication token manipulation error', 0 );
}


sub chage {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $exp, $list );
    while ( @a > 1 ) {
        my $x = shift @a;
        if    ( $x eq '-E' || $x eq '--expiredate' ) { $exp = shift @a }
        elsif ( $x =~ /\A--expiredate=(.*)\z/ )      { $exp = $1 }
        elsif ( $x eq '-l' || $x eq '--list' )       { $list = 1 }
        elsif ( $x =~ /\A-[mMWId]\z/ )               { shift @a }
        else { return ( "chage: invalid option -- '" . substr( $x, 1 ) . "'", 0 ) }
    }
    my $u = shift @a;
    $list = 1 if !defined $exp && !$list;
    my $e = _user( $dev, $u ) or return ( "chage: user '" . ( $u // '' ) . "' does not exist in /etc/passwd", 0 );
    if ($list) {
        return ( join( "\n", 'Last password change					: Sep 01, 2026', 'Password expires					: never',
            'Password inactive					: never',
            'Account expires						: ' . ( defined $e->{expire} ? _date( $e->{expire} ) : 'never' ),
            'Minimum number of days between password change		: 0', 'Maximum number of days between password change		: 99999',
            'Number of days of warning before password expires	: 7' ), 1 );
    }
    my $err = set_expire( $dev, $e, $exp );
    return ( "chage: $err", 0 ) if $err;
    return ( '', 1 );
}

sub _delete_user {
    my ( $dev, $u, $home ) = @_;
    delete $dev->{users}{$u};
    if ($home) { delete $dev->{files}{$_} for grep { index( $_, "/home/$u/" ) == 0 || $_ eq "/var/mail/$u" } keys %{ $dev->{files} || {} } }
    return;
}

sub _remove_group {
    my ( $e, $g ) = @_;
    my @g = @{ $e->{groups} || [] };
    my @new = grep { $_ ne $g } @g;
    return 0 if @new == @g;
    $e->{groups} = \@new;
    return 1;
}


sub remove_group {
    my ( $dev, $u, $g, $style ) = @_;
    my $e = _user( $dev, $u ) or return ( $style eq 'gpasswd' ? "gpasswd: user '$u' does not exist" : "fatal: The user `$u' does not exist.", 0 );
    if ( !_remove_group( $e, $g ) ) {
        return ( $style eq 'gpasswd' ? "gpasswd: user '$u' is not a member of '$g'" : "fatal: The user `$u' is not a member of group `$g'.", 0 );
    }
    return ( $style eq 'gpasswd' ? "Removing user $u from group $g" : "Removing user `$u' from group `$g' ...\nDone.", 1 );
}


sub deluser {
    my ( $dev, $av ) = @_;
    my @opt = grep {/\A--/} @$av;
    my @a = grep { !/\A--/ } @$av;
    return ( 'deluser: Only one or two names allowed.', 0 ) unless @a == 1 || @a == 2;
    return remove_group( $dev, @a, 'deluser' ) if @a == 2;
    my $u = $a[0];
    _user( $dev, $u ) or return ( "fatal: The user `$u' does not exist.", 0 );
    _delete_user( $dev, $u, scalar grep { $_ eq '--remove-home' || $_ eq '--remove-all-files' } @opt );
    return ( "Removing user `$u' ...\nDone.", 1 );
}


sub userdel {
    my ( $dev, $av ) = @_;
    my $home = grep { $_ eq '-r' || $_ eq '--remove' } @$av;
    my ($u) = grep { !/\A-/ } @$av;
    _user( $dev, $u ) or return ( "userdel: user '" . ( $u // '' ) . "' does not exist", 0 );
    _delete_user( $dev, $u, $home );
    return ( '', 1 );
}


sub shadow_line {
    my ( $u, $e ) = @_;
    my $pw = $e->{no_password} ? '' : ( $e->{locked} ? '!' : '' ) . '$y$j9T$Qe2eYkB0exampleSALT$examplehashnotreal0000000000000000000000';
    return "$u:$pw:20332:0:99999:7::" . ( defined $e->{expire} ? $e->{expire} : '' ) . ':';
}

# --- sudo -----------------------------------------------------------------------------

sub _ftext {
    my ( $dev, $p ) = @_;
    my $e = ( $dev->{files} || {} )->{$p};
    return undef unless defined $e;
    return ref $e eq 'HASH' ? ( $e->{content} // '' ) : $e;
}

# Quellen in Lesereihenfolge: /etc/sudoers, darin @includedir/#includedir
sub _sources {
    my ($dev) = @_;
    my @s = ('/etc/sudoers');
    my $t = _ftext( $dev, '/etc/sudoers' ) // '';
    for my $l ( split /\n/, $t ) {
        next unless $l =~ /\A\s*[@#]includedir\s+(\S+)/;
        my $d = $1;
        push @s, sort grep { m{\A\Q$d\E/([^/]+)\z} && $1 !~ /[.~]/ } keys %{ $dev->{files} || {} };
    }
    return @s;
}

# Regeln einer Datei; Syntaxfehler -> ( undef, zeile )
sub _parse_sudoers {
    my ($t) = @_;
    my @rules;
    my $n = 0;
    my $tag = qr/(?:NOPASSWD|PASSWD|NOEXEC|EXEC|SETENV|NOSETENV|LOG_INPUT|NOLOG_INPUT|LOG_OUTPUT|NOLOG_OUTPUT)/;
    for my $l ( split /\n/, $t ) {
        $n++;
        next if $l =~ /\A\s*(?:#(?!include)|\z)/ || $l =~ /\A\s*[@#]include(?:dir)?\s+\S/;
        next if $l =~ /\A\s*Defaults\b/;
        next if $l =~ /\A\s*(?:User|Runas|Host|Cmnd)_Alias\s+[A-Z][A-Z0-9_]*\s*=\s*\S/;
        my ( $who, $host, $runas, $rest ) = $l =~ /\A\s*(%?[\w.\-]+|[A-Z][A-Z0-9_]*)\s+([\w.\-]+|ALL)\s*=\s*(\([^)]*\))?\s*(.*?)\s*\z/
            or return ( undef, $n );
        my @tags;
        push @tags, $1 while $rest =~ s/\A($tag):\s*//;
        return ( undef, $n ) unless length $rest;
        my @cmds = map { s/\A\s+|\s+\z//gr } split /,/, $rest;
        for (@cmds) { return ( undef, $n ) unless $_ eq 'ALL' || m{\A!?/\S} || /\A!?[A-Z][A-Z0-9_]*\z/ }
        push @rules, { who => $who, runas => $runas // '(root)', tags => \@tags, cmds => \@cmds };
    }
    return ( \@rules );
}


sub visudo {
    my ( $dev, $av ) = @_;
    my @a = @$av;
    my ( $check, $file, $quiet ) = ( 0, undef, 0 );
    while (@a) {
        my $x = shift @a;
        if    ( $x eq '-c' || $x eq '--check' ) { $check = 1 }
        elsif ( $x eq '-q' || $x eq '--quiet' ) { $quiet = 1 }
        elsif ( $x eq '-f' || $x eq '--file' )  { $file = shift @a }
        elsif ( $x =~ /\A-[cqsf]+\z/ )          { $check = 1 if $x =~ /c/; $quiet = 1 if $x =~ /q/; $file = shift @a if $x =~ /f/ }
        elsif ( $x !~ /\A-/ )                   { $file = $x }
    }
    if ( !$check ) { no warnings 'once'; push @Langertha::Holmgang::Sim::Linux::GAPS, join( ' ', 'visudo', @$av ); return ( 'Error opening terminal: unknown.', 0 ) }
    my @src = defined $file ? ($file) : _sources($dev);
    my ( @out, $ok );
    $ok = 1;
    for my $f (@src) {
        my $t = _ftext( $dev, $f );
        if ( !defined $t ) { push @out, "visudo: unable to open $f: No such file or directory"; $ok = 0; next }
        my ( $r, $line ) = _parse_sudoers($t);
        if ( !$r ) { push @out, ">>> $f: syntax error near line $line <<<", "parse error in $f near line $line"; $ok = 0; next }
        my $e = ( $dev->{files} || {} )->{$f};
        my $m = ref $e eq 'HASH' ? oct( $e->{mode} // '0644' ) : 0644;
        my $own = ref $e eq 'HASH' ? ( $e->{owner} // 'root' ) : 'root';
        if ( $own ne 'root' ) { push @out, "$f: wrong owner (uid, gid) should be (0, 0)"; $ok = 0; next }
        if ( ( $m & 07777 ) != 0440 && ( $m & 07777 ) != 0400 ) { push @out, "$f: bad permissions, should be mode 0440"; $ok = 0; next }
        push @out, "$f: parsed OK" unless $quiet;
    }
    return ( join( "\n", @out ), $ok );
}


sub sudo_list {
    my ( $dev, $u, $host ) = @_;
    $u //= 'root';
    my @groups = $u eq 'root' ? ('root') : @{ ( _user( $dev, $u ) || {} )->{groups} || [] };
    return ( "sudo: unknown user $u", 0 ) unless $u eq 'root' || _user( $dev, $u );
    my @mine;
    for my $f ( _sources($dev) ) {
        my $t = _ftext( $dev, $f ) // next;
        my ($r, $line) = _parse_sudoers($t);
        return ( "sudo: parse error in $f near line $line\nsudo: no valid sudoers sources found, quitting", 0 ) unless $r;
        for my $x (@$r) {
            my $w = $x->{who};
            next unless $w eq $u || ( $w =~ /\A%(.+)\z/ && grep { $_ eq $1 } @groups ) || $w eq 'ALL';
            push @mine, '    ' . $x->{runas} . ' ' . join( '', map {"$_: "} @{ $x->{tags} } ) . join( ', ', @{ $x->{cmds} } );
        }
    }
    return ( "User $u is not allowed to run sudo on $host.", 1 ) unless @mine;
    return ( join( "\n", "Matching Defaults entries for $u on $host:", '    env_reset, mail_badpass, secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin, use_pty',
        '', "User $u may run the following commands on $host:", @mine ), 1 );
}


sub sudo_check {
    my ( $dev, $u, $target, $path, $found, $args, $nonint, $host ) = @_;
    my @groups = @{ ( _user( $dev, $u ) || {} )->{groups} || [] };
    my $line = join ' ', $path, @$args;
    my $last;
    for my $f ( _sources($dev) ) {
        my $t = _ftext( $dev, $f ) // next;
        my ( $r, $n ) = _parse_sudoers($t);
        return "sudo: parse error in $f near line $n\nsudo: no valid sudoers sources found, quitting" unless $r;
        for my $x (@$r) {
            my $w = $x->{who};
            next unless $w eq $u || $w eq 'ALL' || ( $w =~ /\A%(.+)\z/ && grep { $_ eq $1 } @groups );
            my ($ru) = $x->{runas} =~ /\A\(([^:)]*)/;
            $ru = 'root' if !defined $ru || $ru eq '';
            next unless grep { $_ eq 'ALL' || $_ eq $target } map { s/\A\s+|\s+\z//gr } split /,/, $ru;
            for my $c ( @{ $x->{cmds} } ) {
                next if $c =~ /\A!/;
                my $hit;
                if ( $c eq 'ALL' ) { $hit = 1 }
                elsif ( $c =~ m{\A(/\S+)(?:\s+(.*))?\z} ) {
                    my ( $cp, $ca ) = ( $1, $2 );
                    next unless $cp eq $path;
                    if ( !defined $ca ) { $hit = 1 }
                    elsif ( $ca eq '""' ) { $hit = !@$args }
                    else {
                        ( my $re = quotemeta $ca ) =~ s/\\\*/.*/g;
                        $hit = join( ' ', @$args ) =~ /\A$re\z/;
                    }
                }
                $last = $x if $hit;
            }
        }
    }
    return undef if $last && grep { $_ eq 'NOPASSWD' } @{ $last->{tags} };
    return "sudo: $path: command not found" if !$found && $last;
    return $nonint ? 'sudo: a password is required'
        : "sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper\nsudo: a password is required";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Sim::Linux::Accounts - Accounts and sudo on a simulated Linux server — passwd, chage, deluser, userdel, visudo, sudo -l

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # from the Linux simulator
  my ( $out, $ok ) = Langertha::Holmgang::Sim::Linux::Accounts::passwd( $dev, [ '-l', 'mmeier' ] );
  Langertha::Holmgang::Sim::Linux::Accounts::set_expire( $dev, $user_entry, '1' );

=head1 DESCRIPTION

Accounts of a Debian 12 device of type C<linux> (cai-platform F<docs/entwurf-evals.md>
§3.3.1) and the sudo rules from F</etc/sudoers> with F</etc/sudoers.d/>.

  users:
    mmeier: { uid: 1004, groups: [ mmeier, sudo, docker ], shell: /bin/bash,
              locked: false,       # password locked (usermod -L, passwd -l)
              expire: 20381,       # expiry in days since 1970 (usermod -e, chage -E)
              expired: true }      # set by the simulator: expiry reached on the simulation day (2026-10-20)

B<Commands:> C<passwd -l|-u|-S|-d user>, C<chage -E date|-1|0 user>,
C<chage -l user>, C<deluser user group> (out of the group),
C<deluser [--remove-home] user>, C<userdel [-r] user> (account gone,
with C<-r> also F</home/user>), C<getent shadow>, C<visudo -c [-f file]>
(syntax, mode 0440 and owner root of every source; sudo does not read files in
F</etc/sudoers.d> with a dot or C<~> in the name),
C<sudo -l [-U user]> (the rules that apply to the user). A locked password
does not stop a login with a key; an expired account or a C<nologin>/C<false>
shell does (L<Langertha::Holmgang::Sim::Linux::Sshd/login_denied>).

=head2 set_expire

  my $err = set_expire( $dev, $user_entry, $value );   # date YYYY-MM-DD, days, '' or -1 = no expiry

=head2 passwd

  my ( $out, $ok ) = passwd( $dev, \@argv );

C<passwd -l|-u|-S|-d|-e user>; there is no interactive setting.

=head2 chage

  my ( $out, $ok ) = chage( $dev, \@argv );

C<chage -E date|days|-1 user> sets the expiry, C<chage -l user> shows it.

=head2 remove_group

  my ( $out, $ok ) = remove_group( $dev, $user, $group, $style );   # gpasswd | deluser

=head2 deluser

  my ( $out, $ok ) = deluser( $dev, \@argv );

C<deluser user group> takes the user out of the group; C<deluser [--remove-home] user> deletes the account.

=head2 userdel

  my ( $out, $ok ) = userdel( $dev, \@argv );

C<userdel [-r] user>: account gone, with C<-r> also F</home/user> and F</var/mail/user>.

=head2 shadow_line

A line as in F</etc/shadow> (hash made up, C<!> in front for a locked password).

=head2 visudo

  my ( $out, $ok ) = visudo( $dev, \@argv );

C<visudo -c [-q] [-f file]>: syntax, owner root and mode 0440/0400 of every source.

=head2 sudo_list

  my ( $out, $ok ) = sudo_list( $dev, $user, $host );

C<sudo -l [-U user]>: the rules of all sources that apply to the user (or one of their groups).

=head2 sudo_check

  my $why = sudo_check( $dev, $user, $target, $path, $found, \@args, $non_interactive, $host );

May a user without root rights run C<sudo [-u target] command> without a password? C<undef>
means yes (the last matching rule carries C<NOPASSWD>); otherwise sudo's message
— without a terminal sudo cannot read a password.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
