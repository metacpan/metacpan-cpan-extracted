#! perl

# Copyright (c) 2016 cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# Distributed under the terms of the MIT license.  See the LICENSE file for
# further details.

use strict;
use warnings;

use File::Temp ();

use Mail::Dir ();

use Test::More ( 'tests' => 68 );
use Test::Exception;
use Errno;

sub create_message_text {
    return <<EOF;
From: Foo
To: Bar
Subject: Cats

Meow!
EOF
}

sub create_message_file {
    my ($file) = @_;

    open( my $fh, '>', $file ) or die("Unable to open $file for writing: $!");
    print {$fh} create_message_text();
    close $fh;

    return $file;
}

sub create_message_sub {
    return sub {
        my ($fh) = @_;
        print {$fh} create_message_text();
        return;
    };
}

sub create_tmp_message {
    my ( $maildir, $age ) = @_;

    $age ||= 0;
    my $time = time() - $age;

    my $dir = "$maildir->{'dir'}/tmp";

    my $name = $maildir->name(
        'from' => create_message_sub(),
        'time' => $time
    );

    my $file = "$dir/$name";

    create_message_file($file);

    utime( $time, $time, $file );

    return $file;
}

my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 );

{
    note('Testing plain Maildir support');

    my $maildir_path = "$tmpdir/Maildir";
    my $maildir;

    throws_ok {
        Mail::Dir->open;
    }
    qr/^No Maildir path specified/, 'Mail::Dir->open() die()s if no directory was provided';

    throws_ok {
        Mail::Dir->open(
            '/dev/null/impossible',
            'create' => 1
        );
    }
    qr/^Unable to mkdir\(\)/, 'Mail::Dir->open() die()s with "create" if it cannot create a directory';

    throws_ok {
        Mail::Dir->open('/dev/null');
    }
    qr/^\/dev\/null: Not a directory/, 'Mail::Dir->open() die()s if passed a non-directory path';

    eval { Mail::Dir->open($maildir_path); };

    ok( defined $@ && $!{'ENOENT'}, 'Mail::Dir->open() die()s if asked to open nonexistent Maildir' );

    lives_ok {
        $maildir = Mail::Dir->open(
            $maildir_path,
            'create' => 1
        );
    }
    'Mail::Dir->open() is able to create a nonexistent Maildir';

    lives_ok {
        Mail::Dir->open(
            $maildir_path,
            'create' => 1
        );
    }
    'Mail::Dir->open() will not complain if "create" passed on existing Maildir';

    lives_ok {
        Mail::Dir->open($maildir_path);
    }
    'Mail::Dir->open() will successfully open an existing Maildir directory';

    throws_ok {
        $maildir->select_mailbox('INBOX');
    }
    qr/^\QMaildir++ extensions not enabled\E/, '$maildir->select_mailbox() die()s when running on a mailbox without Maildir++ extensions';

    throws_ok {
        $maildir->create_mailbox('INBOX.new');
    }
    qr/^\QMaildir++ extensions not enabled\E/, '$maildir->create_mailbox() die()s when running on a mailbox without Maildir++ extensions';

    throws_ok {
        $maildir->deliver;
    }
    qr/^No message source provided/, '$maildir->deliver() die()s when no message source provided';

    note('Testing Maildir message delivery');

    my $msgfile = "$tmpdir/msg.txt";

    create_message_file($msgfile);

    lives_ok {
        $maildir->deliver($msgfile);
    }
    '$maildir->deliver() succeeds when delivering message from file';

    lives_ok {
        $maildir->deliver( create_message_sub() );
    }
    '$maildir->deliver() succeeds when delivering message from CODE ref';

    open( my $fh, '<', $msgfile );

    lives_ok {
        $maildir->deliver($fh);
    }
    '$maildir->deliver() succeeds when delivering message from file handle';

    close $fh;

    note('Testing Maildir message retrieval');

    is( scalar @{ $maildir->messages() } => 0, '$maildir->messages() returns nothing when passed no options' );

    {
        my $messages = $maildir->messages(
            'tmp' => 1,
            'new' => 1,
            'cur' => 1
        );

        is( scalar @{$messages} => 3, '$maildir->messages() returns 3 messages for tmp, new and cur without a filter' );
    }

    {
        my $messages = $maildir->messages(
            'tmp' => 1,
            'new' => 1,
            'cur' => 1
        );

        foreach my $message ( @{$messages} ) {
            my $fh;

            lives_ok {
                $fh = $message->open;
            }
            '$message->open() able to open message as file';

            close $fh if $fh;
        }
    }

    {
        my $messages = $maildir->messages(
            'tmp'    => 1,
            'new'    => 1,
            'cur'    => 1,
            'filter' => sub {
                my ($message) = @_;
                my $match = 0;

                my $fh = $message->open;

                while ( my $line = readline($fh) ) {
                    chomp $line;

                    if ( $line =~ /^From: Foo/ ) {
                        $match = 1;
                        last;
                    }
                }

                return $match;
            }
        );

        is( scalar @{$messages} => 3, '$maildir->messages() able to retrieve all messages successfully with filter' );
    }

    {
        note('Testing Maildir tmp message purging');
        note('Queueing 38 hour-old message in tmp');

        my $oldtmpfile = create_tmp_message( $maildir, 60 * 60 * 38 );
        my $newtmpfile = create_tmp_message($maildir);

        lives_ok {
            $maildir->purge;
        }
        '$maildir->purge() does not die() when purging messages';

        ok( !-f $oldtmpfile, '$maildir->purge() deleted messages older than 36 hours' );
        ok( -f $newtmpfile,  '$maildir->purge() does not delete messages less than 36 hours old' );
    }
}

{
    note('Testing with Maildir++ extensions');

    my $maildir_path = "$tmpdir/MaildirPlusPlus";
    my $maildir;

    lives_ok {
        $maildir = Mail::Dir->open(
            $maildir_path,
            'create'    => 1,
            'maildir++' => 1
        );
    }
    'Mail::Dir->open() will create a new Maildir++ queue without complaint';

    lives_ok {
        Mail::Dir->open(
            $maildir_path,
            'maildir++' => 1
        );
    }
    'Mail::Dir->open() will open an existing Maildir++ queue without complaint';

    lives_ok {
        $maildir->select_mailbox('INBOX');
    }
    '$maildir->select_mailbox() will change the mailbox to INBOX without complaint';

    throws_ok {
        $maildir->select_mailbox('INBOX.nonexistent');
    }
    qr/^Mailbox does not exist/, '$maildir->select_mailbox() die()s when passed a nonexistent mailbox';

    lives_ok {
        $maildir->create_mailbox('INBOX.new');
    }
    '$maildir->create_mailbox() successfully creates a new mailbox';

    throws_ok {
        $maildir->create_mailbox('INBOX.impossible.mailbox');
    }
    qr/^Parent mailbox does not exist/, '$maildir->create_inbox() die()s when passed a mailbox path with nonexistent parent';

    lives_ok {
        $maildir->select_mailbox('INBOX.new');
    }
    '$maildir->select_mailbox() will change the mailbox to INBOX.new without complaint';

    throws_ok {
        $maildir->select_mailbox('//invalid');
    }
    qr/^Invalid mailbox name/, '$maildir->select_mailbox() will die() if provided an invalid mailbox name';

    note('Testing Maildir++ message delivery');

    my $msgfile = "$tmpdir/msg.txt";
    my $message;

    create_message_file($msgfile);

    lives_ok {
        $maildir->deliver($msgfile);
    }
    '$maildir->deliver() succeeds when delivering message from file';

    lives_ok {
        $maildir->deliver( create_message_sub() );
    }
    '$maildir->deliver() succeeds when delivering message from CODE ref';

    open( my $fh, '<', $msgfile );

    lives_ok {
        $message = $maildir->deliver($fh);
    }
    '$maildir->deliver() succeeds when delivering message from file handle';

    close $fh;

    ok( -f $message->{'file'}, '$maildir->deliver() actually delivers message to new file' );
    is( $message->{'dir'} => 'new', '$maildir->deliver() delivers mail to "new" queue' );

    my $old_file = $message->{'file'};

    lives_ok {
        $message->move('INBOX');
    }
    '$maildir->move() successfully moves message from INBOX.new to INBOX';

    my $new_file = $message->{'file'};

    isnt( $old_file => $new_file, '$maildir->move() actually relocated message from INBOX.new to INBOX' );

    note('Testing message flags; first, with no flags set');

    ok( !$message->passed,  '$maildir->passed() returns false' );
    ok( !$message->replied, '$maildir->replied() returns false' );
    ok( !$message->seen,    '$maildir->seen() returns false' );
    ok( !$message->trashed, '$maildir->trashed() returns false' );
    ok( !$message->draft,   '$maildir->draft() returns false' );
    ok( !$message->flagged, '$maildir->flagged() returns false' );

    my $flags   = 'PRSTDF';
    my $flaglen = length $flags;
    my $found   = $message->flags();

    for ( my $i = 0; $i < $flaglen; $i++ ) {
        my $flag = substr $flags, $i, 1;

        is( index( $found, $flag ) => -1, '$maildir->flags() does not indicate flag ' . $flag . ' yet' );
    }

    note("Setting message flags $flags");

    lives_ok {
        $message->mark($flags);
    }
    '$message->mark() does not die() when setting message flags ' . $flags;

    $found = $message->flags;

    for ( my $i = 0; $i < $flaglen; $i++ ) {
        my $flag = substr $flags, $i, 1;

        ok( index( $found, $flag ) >= 0, '$maildir->flags() indicates flag ' . $flag );
    }

    ok( $message->passed,  '$maildir->passed() returns true' );
    ok( $message->replied, '$maildir->replied() returns true' );
    ok( $message->seen,    '$maildir->seen() returns true' );
    ok( $message->trashed, '$maildir->trashed() returns true' );
    ok( $message->draft,   '$maildir->draft() returns true' );
    ok( $message->flagged, '$maildir->flagged() returns true' );
}

{
    my $tmpdir = File::Temp::tempdir( 'cleanup' => 1 );

    my $maildir = Mail::Dir->open(
        $tmpdir,
        'create'    => 1,
        'maildir++' => 1
    );

    my %TESTS = (
        'INBOX'               => $tmpdir,
        'INBOX.foo'           => "$tmpdir/.INBOX.foo",
        'INBOX.bar'           => "$tmpdir/.INBOX.bar",
        'Spam'                => "$tmpdir/.Spam",
        'Dating.PlentyOfFish' => "$tmpdir/.Dating.PlentyOfFish",
        'Dating.OkCupid'      => "$tmpdir/.Dating.OkCupid"
    );

    note('Testing mailbox directory mapping');

    foreach my $mailbox ( sort keys %TESTS ) {
        my $expected = $TESTS{$mailbox};

        is( $maildir->mailbox_dir($mailbox) => $expected, "Mailbox $mailbox maps to directory $expected" );
    }
}
