#!/usr/bin/env perl

package t::IO::Die;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use base qw(
  Test::Class
);

use List::Util qw(reduce);
our ( $a, $b );

use Cwd    ();
use Socket ();
use Errno  ();
use Fcntl;

use Test::More;
use Test::NoWarnings;
use Data::Dumper;
use Test::Deep;
use Test::Exception;

use File::Basename ();
use File::Path     ();
use File::Spec::Functions;
use File::Temp ();

use IO::Handle ();

use IO::Die ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub runtests {
    my ( $self, @args ) = @_;

    my $curdir = Cwd::abs_path( File::Basename::dirname(__FILE__) );

    my $scratch_dir = catdir( $curdir, "scratch-$$-" . time );
    mkdir $scratch_dir;

    my $ppid   = $$;
    my $at_end = t::IO::Die::Finally->new(
        sub {
            return if $$ != $ppid;
            File::Path::remove_tree($scratch_dir);
        }
    );

    local $ENV{'TMPDIR'} = $scratch_dir;

    local $| = 1;

    return $self->SUPER::runtests(@args);
}

sub _dummy_user {
    my ($self) = @_;

    if ( !$self->{'_dummy_user'} ) {
        for my $u (qw( nobody bin daemon )) {
            if ( getpwnam($u) && getgrnam($u) ) {
                $self->{'_dummy_user'} = $u;
                last;
            }
        }
    }

    return $self->{'_dummy_user'};
}

sub tempdir {
    local ( $!, $^E );
    return File::Temp::tempdir( CLEANUP => 1 );
}

sub tempfile {
    local ( $!, $^E );
    my @fh_and_name = File::Temp::tempfile( CLEANUP => 1 );

    return wantarray ? reverse(@fh_and_name) : $fh_and_name[1];
}

sub _to_bitmask {
    my ( $self, @fhs ) = @_;

    my $mask = q<>;

    for my $fh (@fhs) {
        vec( $mask, fileno($fh), 1 ) = 1;
    }

    return $mask;
}

sub test_open_for_fork_to_perl : Tests(2) {
    my ($self) = @_;

    pipe my $p_rdr, my $c_wtr;

    local $! = 7;

    my $fh;
    my $pid = IO::Die->open( $fh, '|-' );

    if ( !$pid ) {
        IO::Die->close($p_rdr);
        IO::Die->print( $c_wtr, <> );
        exit;
    }

    is( 0 + $!, 7, 'raw fork open() leaves $! alone' );

    IO::Die->close($c_wtr);
    IO::Die->print( $fh, 'haha' );

    {
        local $?;
        IO::Die->close($fh);

        is( <$p_rdr>, 'haha', 'pipe as STDIN works' );
    }

    return;
}

sub test_open_for_fork_from_perl : Tests(2) {
    my ($self) = @_;

    local $! = 7;

    my $fh;
    my $pid = IO::Die->open( $fh, '-|' );

    if ( !$pid ) {
        IO::Die->print('heyhey');
        exit;
    }

    is( 0 + $!, 7, 'raw fork open() leaves $! alone' );

    {
        is( <$fh>, 'heyhey', 'pipe as STDOUT works' );

        local $?;
        IO::Die->close($fh);
    }

    return;
}

sub test_dup_filehandle : Tests(2) {
    my ($self) = @_;

    my ( $file, $wfh ) = $self->tempfile();

    print {$wfh} '123';
    close $wfh;

    IO::Die->open( my $orig_fh, '<', $file );

    IO::Die->open( my $dup_fh, '<&', $orig_fh );

    is( <$dup_fh>, '123', 'open(<&) works' );

    isnt(
        fileno($orig_fh),
        fileno($dup_fh),
        '...and the filehandles are different',
    );

    return;
}

sub test_clone_filehandle : Tests(2) {
    my ($self) = @_;

    my ( $file, $wfh ) = $self->tempfile();

    print {$wfh} '123';
    close $wfh;

    IO::Die->open( my $orig_fh, '<', $file );

    IO::Die->open( my $clone_fh, '<&=', $orig_fh );

    is( <$clone_fh>, '123', 'open(<&) works' );

    is(
        fileno($orig_fh),
        fileno($clone_fh),
        '...and the filehandles are the same file descriptor',
    );

    return;
}

sub test_open_on_a_scalar_ref : Tests(3) {
    my ($self) = @_;

    my $fh;

  SKIP: {
        skip 'Need Perl 5.8.9 at least!', $self->num_tests() if $^V lt v5.8.9;

        my $ok = IO::Die->open( $fh, '<', \123 );
        ok( $ok, 'opened file handle to read from a scalar ref (constant)' );

        is( <$fh>, 123, '...and the file handle reads fine' );

        dies_ok(
            sub { IO::Die->open( $fh, '>', \123 ) },
            'error from creating write-to file handle on a scalar ref constant',
        );
    }

    return;
}

sub test_open_on_a_file : Tests(6) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    local $! = 7;

    lives_ok(
        sub { IO::Die->open( my $wfh, '>', catfile( $dir, 'somefile' ) ) },
        'open(>) on a new file',
    );
    ok( ( -f catfile( $dir, "somefile" ) ), '...and it really did open()' );

    is( 0 + $!, 7, '...and it left $! alone' );

    dies_ok(
        sub { IO::Die->open( my $wfh, ">" . catfile( $dir, 'somefile' ) ) },
        'open(>) fails on 2-arg',
    );

    dies_ok(
        sub { IO::Die->open( my $wfh, '<', catfile( $dir, 'otherfile' ) ) },
        'open(<) on a nonexistent file',
    );
    like( $@, qr<FileOpen>, '...and the error' );

    return;
}

sub test_open_from_a_command : Tests(9) {
    my ($self) = @_;

    my ( $rfh, $pid );

    lives_ok(
        sub { $pid = IO::Die->open( $rfh, '-|', 'echo hi' ) },
        'open() from a space-delimited command',
    );
    is( <$rfh>, "hi$/", '...and it really does open() from the command' );
    like( $pid, qr<\A[0-9]+\z>, '...and it returns the PID' );

    lives_ok(
        sub { IO::Die->open( $rfh, '-|', 'echo', 'hi' ) },
        'open() from a command with list args',
    );
    is( <$rfh>, "hi$/", '...and it really does open() from the command' );

    dies_ok(
        sub { IO::Die->open( $rfh, '-|', 'echo hi', undef ) },
        'open() from a nonexistent command with a space in it',
    );
    like( $@, qr<Exec>, '..and the exception' );

    my $dir = $self->tempdir();

    dies_ok(
        sub { IO::Die->open( $rfh, '-|', catfile( $dir, 'hahaha' ) ) },
        'open() from a nonexistent command',
    );
    like( $@, qr<Exec>, '..and the exception' );

    return;
}

sub test_chroot : Tests(1) {
    my ($self) = @_;

  SKIP: {
        skip 'Must be root!', 1 if $>;

        my $dir = $self->tempdir();
        do { open my $wfh, '>', catfile( $dir, 'thefile' ); print {$wfh} 'thecontent' };

        mkdir catdir( $dir, 'thedir' );
        do { open my $wfh, '>', catfile( $dir, 'thedir', 'f' ); print {$wfh} 'thatcontent' };

        pipe my $p_rd, my $c_wr;

        my $cpid = fork() or do {
            my $at_end = t::IO::Die::Finally->new( sub { exit } );
            close $p_rd;

            eval {
                chdir $dir;
                $! = 7;
                IO::Die->chroot($dir);
                my $num = $! + 0;

                open my $rfh, '<', 'thefile';
                my $content = <$rfh>;
                print {$c_wr} "$num,$content$/";
                close $rfh;

                chdir 'thedir';
                $! = 7;
                IO::Die->chroot() for catdir( rootdir(), 'thedir' );
                $num = $! + 0;

                open $rfh, '<', 'f';
                $content = <$rfh>;
                print {$c_wr} "$num,$content$/";
                close $rfh;

                close $c_wr;
            };
            diag explain $@ if $@;
        };

        close $c_wr;

        my @lines = <$p_rd>;
        is_deeply(
            \@lines,
            [ "7,thecontent$/", "7,thatcontent$/" ],
            'chroot(): with argument, without argument',
        ) or diag explain \@lines;

        close $p_rd;

        local $?;
        waitpid $cpid, 0;
    }

    return;
}

sub test_open_to_a_command : Tests(9) {
    my ($self) = @_;

    my ( $rfh, $pid );

    my $stdout;

    local $@;

    my ($tempfile) = $self->tempfile();

    eval {
        $pid = IO::Die->open( $rfh, '|-', qq[perl -e "open TEMP, '>', '$tempfile'; print TEMP <>"] );
        IO::Die->print( $rfh, 'ohyeah' );
        IO::Die->close($rfh);
    };
    ok( !$@, 'open() from a space-delimited command' );

    is(
        do { open my $fh, '<', $tempfile; <$fh> },
        "ohyeah",
        '...and it really does open() to the command',
    );

    like( $pid, qr<\A[0-9]+\z>, '...and it returns the PID' );

    $tempfile = $self->tempfile();

    eval {
        IO::Die->open( $rfh, '|-', 'perl', -e => "open TEMP, '>', '$tempfile'; print TEMP 123; print TEMP <>" );
        IO::Die->print( $rfh, 'ohyeah' );
        IO::Die->close($rfh);
    };
    ok( !$@, 'open() to a command with list args' );

    is(
        do { open my $fh, '<', $tempfile; <$fh> },
        '123ohyeah',
        '...and it obeys parameters and still open()s to the command',
    );

    dies_ok(
        sub { IO::Die->open( $rfh, '|-', 'echo hi', undef ) },
        'open() to a nonexistent command with a space in it',
    );
    like( $@, qr<Exec>, '..and the exception' );

    my $dir = $self->tempdir();

    dies_ok(
        sub { IO::Die->open( $rfh, '|-', catfile( $dir, 'hahaha' ) ) },
        'open() to a nonexistent command',
    );
    like( $@, qr<Exec>, '..and the exception' );

    return;
}

sub test_sysopen : Tests(7) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    my ( $opened, $fh );
    dies_ok(
        sub { $opened = IO::Die->sysopen( $fh, catfile( $dir, 'notthere' ), Fcntl::O_RDONLY ) },
        'sysopen(O_RDONLY) on a nonexistent file',
    );
    like( $@, qr<FileOpen>, '..and the exception' ) or diag explain $@;

    local $! = 7;

    $fh = IO::Handle->new();

    local $@;
    lives_ok(
        sub { $opened = IO::Die->sysopen( $fh, catfile( $dir, 'i_am_here' ), Fcntl::O_CREAT | Fcntl::O_WRONLY, 0600 ) },
        'sysopen(O_CREAT | O_WRONLY) on a nonexistent file',
    );
    ok( $opened, '..and the return is truthy' );
    isa_ok( $fh, 'GLOB', '...and auto-vivification works' );

    is( 0 + $!, 7, '...and it left $! alone' );

    syswrite( $fh, '7' );
    is( ( -s $fh ), 1, '...and the filehandle is a write filehandle' );

    return;
}

sub test_read : Tests(9) {
    my ($self) = @_;

    return $self->_test_read_func( \&IO::Die::read );
}

sub test_sysread : Tests(10) {
    my ($self) = @_;

    $self->_test_read_func( \&IO::Die::sysread );

    #Let's check sysread()'s unbuffered-ness.

    my $dir = $self->tempdir();
    open my $fh, '+>', catfile( $dir, 'somefile' );

    lives_ok(
        sub {
            my $buffer = q<>;
            for ( 1 .. 100 ) {
                my $random = rand;

                sysseek( $fh, 0, 0 );
                truncate $fh, 0;
                syswrite( $fh, $random );
                sysseek( $fh, 0, 0 );
                IO::Die->sysread( $fh, $buffer, length $random );

                die if $buffer ne $random;
            }
        },
        'sysread() is really unbuffered',
    );

    return;
}

sub _test_read_func {
    my ( $self, $func_cr ) = @_;

    my ( $file, $fh ) = $self->tempfile();

    my $alphabet = q<>;
    $alphabet .= $_ for 'a' .. 'z';
    print {$fh} $alphabet;

    close $fh;

    open $fh, '<', $file;

    my $buffer = q<>;

    local $! = 7;

    lives_ok(
        sub { $func_cr->( 'IO::Die', $fh, $buffer, 2 ) },
        'read succeeded',
    );
    is( $buffer, 'ab', '...and actually worked' );

    is( 0 + $!, 7, '...and it left $! alone' );

    $buffer .= '12345';
    my $bytes = $func_cr->( 'IO::Die', $fh, $buffer, 2, -3 );
    is( $buffer, 'ab12cd', 'read obeys OFFSET' );
    is( $bytes,  2,        '...and it returns the number of bytes read' );

    $bytes = $func_cr->( 'IO::Die', $fh, $buffer, 100_000 );
    is( $buffer, 'efghijklmnopqrstuvwxyz', 'read when LENGTH is over size' );
    is( $bytes,  length($buffer),          '...and the number of bytes is correct' );

    close $fh;

    {
        local $SIG{'__WARN__'} = sub { };
        throws_ok(
            sub { $func_cr->( 'IO::Die', $fh, $buffer, 7 ) },
            qr<Read>,
            'error read on a closed filehandle',
        );
    }

    like( $@, qr<7>, '...and the error has the intended number of bytes' );

    return;
}

sub test_print_with_filehandle : Tests(10) {
    my ($self) = @_;

    my ( $file, $fh ) = $self->tempfile();

    $fh->autoflush(1);

    local $! = 7;

    my $printed;
    lives_ok(
        sub { $printed = IO::Die->print( $fh, 'ha', 'ha' ) },
        'print() to a file with a given string',
    );

    ok( $printed, '...and it returns a true value' );

    is( $self->_cat($file), 'haha', '...and the print actually happened' );

    is( 0 + $!, 7, '...and it left $! alone' );

    for ('hoho') {
        lives_ok(
            sub { $printed = IO::Die->print($fh) },
            'print() to a file from $_',
        );
        ok( $printed, '...and it returns a true value' );

        do { local ( $!, $^E ); close $fh };

        is( $self->_cat($file), 'hahahoho', '...and the print actually happened' );
    }

    close $fh;

    open my $rfh, '<', $file;
    dies_ok(
        sub { IO::Die->print($rfh) for 'haha!' },
        'print() dies when writing to a non-write filehandle',
    );
    like( $@, qr<Write>, '...and the exception' );
    like( $@, qr<5>,     '...and the exception contains the total number of bytes' );

    return;
}

sub test_print_without_filehandle : Tests(9) {
    my ($self) = @_;

    my $err;
    {
        my ( $file, $fh ) = $self->tempfile();

        $fh->autoflush(1);

        my $orig_fh = $self->_overwrite_stdout($fh);
        my $at_end = t::IO::Die::Finally->new( sub { select $orig_fh } );

        my $printed;
        lives_ok(
            sub { $printed = IO::Die->print('haha') },
            'print() to a file with a given string',
        );
        ok( $printed, '...and it returns a true value' );
        is( $self->_cat($file), 'haha', '...and the print actually happened' );

        for ('hoho') {
            lives_ok(
                sub { $printed = IO::Die->print() },
                'print() to a file from $_',
            );
            ok( $printed, '...and it returns a true value' );
            is( $self->_cat($file), 'hahahoho', '...and the print actually happened' );
        }

        close $fh;

        dies_ok(
            sub { $printed = IO::Die->print( 'I', 'die' ) },
            'print() dies when the filehandle is closed',
        );
        $err = $@;
    }

    like( $err, qr<Write>, '...and the exception' );
    like( $err, qr<4>,     '...and the exception contains the total number of bytes' );

    return;
}

sub test_syswrite : Tests(14) {
    my ($self) = @_;

    my ( $file, $fh ) = $self->tempfile();

    local $! = 7;

    my $printed;
    lives_ok(
        sub { $printed = IO::Die->syswrite( $fh, 'haha' ) },
        'write to a file with a given string',
    );

    is( 0 + $!, 7, '...and it left $! alone' );

    is( $printed,           4,      '...and it returns the number of bytes' );
    is( $self->_cat($file), 'haha', '...and the write actually happened' );

    IO::Die->syswrite( $fh, 'haha', 1 );
    is( $self->_cat($file), 'hahah', 'We obey LENGTH' );

    IO::Die->syswrite( $fh, 'haha', 1, 1 );
    is( $self->_cat($file), 'hahaha', 'We obey OFFSET' );

    IO::Die->syswrite( $fh, 'abcdefg', 1, -3 );
    is( $self->_cat($file), 'hahahae', 'We obey negative OFFSET' );

    close $fh;

    open my $rfh, '<', $file;

    {
        $SIG{'__WARN__'} = sub { };

        throws_ok(
            sub { IO::Die->syswrite( $rfh, 'abcde' ) },
            qr<Write>,
            'exception when writing to a non-write filehandle',
        );
        like( $@, qr<5>, '...and the exception contains the number of bytes meant to be written' );

        throws_ok(
            sub { IO::Die->syswrite( $rfh, 'abcde', 2 ) },
            qr<2>,
            'The exception contains the correct number of bytes meant to be written if there was a LENGTH',
        );

        throws_ok(
            sub { IO::Die->syswrite( $rfh, 'abcde', 200 ) },
            qr<5>,
            'The exception contains the correct number of bytes meant to be written if there was an over-long LENGTH',
        );

        throws_ok(
            sub { IO::Die->syswrite( $rfh, 'abcde', 2, 1 ) },
            qr<2>,
            'The exception contains the correct number of bytes meant to be written if there was a LENGTH and positive OFFSET',
        );

        throws_ok(
            sub { IO::Die->syswrite( $rfh, 'abcde', 200, 1 ) },
            qr<4>,
            'The exception contains the correct number of bytes meant to be written if there was an over-long LENGTH and positive OFFSET',
        );

        throws_ok(
            sub { IO::Die->syswrite( $rfh, 'abcde', 200, -3 ) },
            qr<3>,
            'The exception contains the correct number of bytes meant to be written if there was an over-long LENGTH and negative OFFSET',
        );
    }

    return;
}

sub test_close_with_filehandle : Tests(6) {
    my ($self) = @_;

    my ( $file, $fh ) = $self->tempfile();

    local $! = 7;

    my $closed;
    lives_ok(
        sub { $closed = IO::Die->close($fh) },
        'close()',
    );
    ok( $closed,            '...and the return value is truthy' );
    ok( !CORE::fileno($fh), '...and the filehandle actually closed' );

    is( 0 + $!, 7, '...and it left $! alone' );

    dies_ok(
        sub { IO::Die->close($fh) },
        'close() dies when the filehandle is already closed',
    );
    like( $@, qr<Close>, '...and the exception' );

    return;
}

sub test_close_without_filehandle : Tests(5) {
    my ($self) = @_;

    my ( $fh, $closed );

    {
        ( undef, $fh ) = $self->tempfile();

        my $orig_fh = $self->_overwrite_stdout($fh);
        my $at_end = t::IO::Die::Finally->new( sub { select $orig_fh } );

        select $fh;    ## no critic qw(ProhibitOneArgSelect)
        close $fh;

        dies_ok(
            sub { $closed = IO::Die->close() },
            'close() dies if the select()ed filehandle is already closed',
        );
        like( $@, qr<Close>, '...and the exception' );
    }

    {
        ( undef, $fh ) = $self->tempfile();

        my $orig_fh = $self->_overwrite_stdout($fh);
        my $at_end = t::IO::Die::Finally->new( sub { select $orig_fh } );

        select $fh;    ## no critic qw(ProhibitOneArgSelect)

        lives_ok(
            sub { $closed = IO::Die->close() },
            'close()',
        );
    }

    ok( $closed,            '...and the return value is truthy' );
    ok( !CORE::fileno($fh), '...and the filehandle actually closed' );

    return;
}

sub test_seek : Tests(5) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    open my $fh, '+>', catfile( $dir, 'file' );
    print {$fh} 'a' .. 'z';

    my $buffer;
    my $sought;

    local $! = 7;

    $sought = IO::Die->seek( $fh, 0, 0 );
    ok( $sought, 'returns a truthy value' );

    is( 0 + $!, 7, '...and it left $! alone' );

    read( $fh, $buffer, 1 );
    is( $buffer, 'a', '...and it went to the beginning' );

    $sought = IO::Die->seek( $fh, -1, Fcntl::SEEK_END );
    read( $fh, $buffer, 1 );
    is( $buffer, 'z', 'seek() to one from the end' );
    ok( $sought, '...and it returns a truthy value' );

    return;
}

sub test_sysseek : Tests(5) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    open my $fh, '+>', catfile( $dir, 'file' );
    syswrite( $fh, $_ ) for 'a' .. 'z';

    my $buffer;
    my $sought;

    local $! = 7;

    $sought = IO::Die->sysseek( $fh, 0, 0 );
    ok( $sought, 'returns a truthy value' );

    is( 0 + $!, 7, '...and it left $! alone' );

    sysread( $fh, $buffer, 1 );
    is( $buffer, 'a', '...and it went to the beginning' );

    $sought = IO::Die->sysseek( $fh, -1, Fcntl::SEEK_END );
    sysread( $fh, $buffer, 1 );
    is( $buffer, 'z', 'seek to one from the end' );
    ok( $sought, '...and it returns a truthy value' );

    return;
}

sub test_truncate : Tests(10) {
    my ($self) = @_;

    my @letters = 'a' .. 'z';
    my $alphabet = reduce { $a . $b } @letters;

    my ( $file, $fh ) = $self->tempfile();
    print {$fh} @letters;

    seek( $fh, 0, Fcntl::SEEK_CUR );

    local $! = 7;

    my $trunc = IO::Die->truncate( $fh, 10 );
    ok( $trunc, 'truncate() on a filehandle returns truthy' );

    is( 0 + $!, 7, '...and it left $! alone' );

    is( $self->_cat($file), substr( $alphabet, 0, 10 ), 'truncate() does its thing' );

    IO::Die->close($fh);

    IO::Die->open( $fh, '<', $file );

    throws_ok(
        sub { IO::Die->truncate( $fh, 10 ) },
        qr<FileTruncate>,
        'error from truncating on read-only filehandle',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    #Cygwin and Solaris seem to use EBADF; others EINVAL.
    my $errstr = join(
        '|',
        map { quotemeta( $self->_errno_to_str( Errno->can($_)->() ) ) }
          qw(
          EBADF
          EINVAL
          )
    );

    like(
        $err,
        qr<$errstr>,
        "exception’s error()",
    ) or diag explain $@;

    $trunc = IO::Die->truncate( $file, 1000 );
    ok( $trunc, 'truncate() returns truthy when truncating a filename' );

    is( ( -s $file ), 1000, '...and the “truncate” to a larger-than-previous size works' );

    IO::Die->unlink($file);

    throws_ok(
        sub { IO::Die->truncate( $file, 10 ) },
        qr<FileTruncate>,
        'error from truncating nonexistent file',
    );
    $err = $@;

    $errstr = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$errstr>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_opendir : Tests(6) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    local $! = 7;

    my $res = IO::Die->opendir( my $dfh, $dir );
    ok( $res, 'return value' );
    isa_ok( $dfh, 'GLOB', 'auto-vivify' );

    is( 0 + $!, 7, '...and it left $! alone' );

    throws_ok(
        sub { IO::Die->opendir( my $dfh, catfile( $dir, 'not_there' ) ) },
        qr<DirectoryOpen>,
        'error from opening nonexistent directory',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_rewinddir : Tests(5) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    my %struct = (
        alpha   => 1,
        beta    => 2,
        gamma   => 3,
        delta   => 4,
        epsilon => 5,
    );
    while ( my ( $fn, $cont ) = each %struct ) {
        open my $fh, '>', catfile( $dir, $fn );
        print {$fh} $cont or die $!;
        close $fh;
    }

    IO::Die->opendir( my $dfh, $dir );

    local $!;

    do { readdir $dfh }
      for ( 1 .. 4 );

    $! = 7;

    IO::Die->rewinddir($dfh);

    is( 0 + $!, 7, 'rewinddir() leaves $! alone' );

    cmp_bag(
        [ grep { !tr<.><> } readdir $dfh ],
        [qw( alpha beta gamma delta epsilon )],
        'rewinddir() did actually rewind the directory',
    );

    IO::Die->closedir($dfh);

    $! = 7;

    throws_ok(
        sub { IO::Die->rewinddir($dfh) },
        qr<DirectoryRewind>,
        'error from closing already-closed directory',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::EBADF() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_closedir : Tests(5) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    IO::Die->opendir( my $dfh, $dir );

    local $! = 7;

    my $res = IO::Die->closedir($dfh);
    ok( $res, 'return value' );

    is( 0 + $!, 7, '...and it left $! alone' );

    {
        local $SIG{'__WARN__'} = sub { };
        throws_ok(
            sub { IO::Die->closedir($dfh) },
            qr<DirectoryClose>,
            'error from closing already-closed directory',
        );
    }
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::EBADF() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub _touch {
    my ( $self, $path ) = @_;

    local ( $!, $^E );
    open my $fh, '>>', $path;
    return;
}

sub _cat {
    my ( $self, $path ) = @_;

    local ( $!, $^E, $/ );
    open my $fh, '<', $path;
    return scalar <$fh>;
}

sub test_unlink : Tests(10) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    for my $n ( 0 .. 9 ) {
        my $path = catfile( $dir, "redshirt$n" );
        $self->_touch($path);
    }

    local $! = 7;

    my $ok = IO::Die->unlink( catfile( $dir, "redshirt0" ) );
    is( $ok, 1, 'returns 1 if one path unlink()ed' );
    ok( !do { local $!; -e catfile( $dir, "redshirt0" ) }, '...and the unlink() worked' );

    is( 0 + $!, 7, '...and it left $! alone' );

    $ok = IO::Die->unlink() for ( catfile( $dir, "redshirt9" ) );
    is( $ok, 1, 'returns 1 if one path unlink()ed (via $_)' );
    ok( !do { local $!; -e catfile( $dir, "redshirt0" ) }, '...and the unlink() worked (via $_)' );

    dies_ok(
        sub { IO::Die->unlink( catfile( $dir, "redshirt1" ), catfile( $dir, "redshirt2" ) ) },
        'die()d with >1 path passed',
    );
    ok( do { local $!; -e catfile( $dir, "redshirt1" ) }, '...and the unlink() did NOT happen' );

    throws_ok(
        sub { IO::Die->unlink( catfile( $dir, "redshirt0" ) ) },
        qr<Unlink>,
        'failure when unlink()ing a nonexistent file',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub _errno_to_str {
    my ( $self, $num ) = @_;

    local $! = $num;

    return "$!";
}

sub test_mkdir : Tests(10) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    local $! = 7;

    my $ok;

    $ok = IO::Die->mkdir() for ( catdir( $dir, "dollar_under" ) );
    is( $ok, 1, 'returns 1 if mkdir() with no args' );
    ok( do { local $!; -e catdir( $dir, "dollar_under" ) }, '...and the mkdir() worked' );

    is( 0 + $!, 7, '...and it left $! alone' );

    $ok = IO::Die->mkdir( catdir( $dir, "one_arg" ) );
    is( $ok, 1, 'returns 1 if one path mkdir()ed' );
    ok( do { local $!; -e catdir( $dir, "one_arg" ) }, '...and the mkdir() worked' );

    $ok = IO::Die->mkdir( catdir( $dir, "with_perms" ), 0111 );
    is( $ok, 1, 'returns 1 if one path mkdir()ed with perms' );
    ok( do { local $!; -e catdir( $dir, "with_perms" ) }, '...and the mkdir() worked' );

    throws_ok(
        sub { IO::Die->mkdir( catdir( $dir, "not_there", "not_a_chance" ) ) },
        qr<DirectoryCreate>,
        'failure when mkdir()ing a directory in a nonexistent directory',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $@,
        qr<$str>,
        "exception’s error()",
      )
      or diag explain $@,

      return;
}

sub test_rmdir : Tests(10) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    mkdir catfile( $dir, "redshirt$_" ) for ( 0 .. 9 );

    local $! = 7;

    my $ok = IO::Die->rmdir( catfile( $dir, "redshirt0" ) );
    is( $ok, 1, 'returns 1 if one path rmdir()ed' );
    ok( !do { local $!; -e catfile( $dir, "redshirt0" ) }, '...and the rmdir() worked' );

    is( 0 + $!, 7, '...and it left $! alone' );

    $ok = IO::Die->rmdir() for ( catfile( $dir, "redshirt9" ) );
    is( $ok, 1, 'returns 1 if one path rmdir()ed (via $_)' );
    ok( !do { local $!; -e catfile( $dir, "redshirt0" ) }, '...and the rmdir() worked (via $_)' );

    dies_ok(
        sub { IO::Die->rmdir( catfile( $dir, "redshirt1" ), catfile( $dir, "redshirt2" ) ) },
        'die()d with >1 path passed',
    );
    ok( do { local $!; -e catfile( $dir, "redshirt1" ) }, '...and the rmdir() did NOT happen' );

    throws_ok(
        sub { IO::Die->rmdir( catfile( $dir, "redshirt0" ) ) },
        qr<DirectoryDelete>,
        'failure when rmdir()ing a nonexistent directory',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_chdir_vms_homedir : Tests(6) {
    my ($self) = @_;

    note 'XXX: I have no idea if this actually works on VMS.';

  SKIP: {
        skip 'Only runs on VMS!', $self->num_tests() if $^O ne 'VMS';

        my $orig_dir = _getcwd();
        my $tdir     = Cwd::abs_path( $self->tempdir() );

        local $! = 5;

        my $at_end = t::IO::Die::Finally->new( sub { chdir $orig_dir } );

        local %ENV = (
            'SYS$HOME' => $tdir,
        );

        ok(
            IO::Die->chdir(),
            q<empty chdir() with $ENV{'SYS$HOME'} (but neither HOME nor LOGDIR) defined>,
        );

        is( _getcwd(), $tdir, '...and it did chdir()' );

        is(
            0 + $!,
            5,
            '...and failure leaves $! alone',
        );

        #----------------------------------------------------------------------

        $ENV{'SYS$HOME'} = catdir( $tdir, "notthere" );

        dies_ok(
            sub { IO::Die->chdir( catdir( $tdir, "notthere" ) ) },
            'chdir() as normal, to a non-existent directory',
        );
        my $err = $@;

        cmp_deeply(
            $err,
            all(
                re(qr<Chdir:>),
                re(qr<path +\Q$ENV{'SYS$HOME'}\E>),
                re(qr<OS_ERROR +>),
                re(qr<EXTENDED_OS_ERROR +>),
            ),
            'exception has the right “goods”',
        );

        is(
            0 + $!,
            5,
            '...and failure leaves $! alone',
        );

        is( _getcwd(), $tdir, '...and it did NOT chdir()' );
    }

    return;
}

sub test_chdir : Tests(22) {
    my ($self) = @_;

    my $orig_dir = _getcwd();

    local ( $!, $^E, $@ );

    my $tdir  = Cwd::abs_path( $self->tempdir() );
    my $tdir2 = Cwd::abs_path( $self->tempdir() );

    $! = 5;

    ok(
        IO::Die->chdir($tdir),
        'chdir() as normal, to an existent directory',
    );

    my $at_end = t::IO::Die::Finally->new( sub { chdir $orig_dir } );

    is( _getcwd(), $tdir, '...and it really did chdir()' );

    is(
        0 + $!,
        5,
        '...and it leaves $! alone',
    );

    #----------------------------------------------------------------------

    my $dir_fh;
    {
        local ( $!, $^E );
        open $dir_fh, '<', $tdir2;
    }

    ok(
        IO::Die->chdir($dir_fh),
        'chdir() to a file handle (??)',
    );

    is( _getcwd(), $tdir2, '...and it really did chdir()' );

    is(
        0 + $!,
        5,
        '...and it leaves $! alone',
    );

    #----------------------------------------------------------------------

    my $dir_dh;
    {
        local ( $!, $^E );
        opendir $dir_dh, $tdir;
    }

    ok(
        IO::Die->chdir($dir_dh),
        'chdir() to a dir handle',
    );

    is( _getcwd(), $tdir, '...and it really did chdir()' );

    is(
        0 + $!,
        5,
        '...and it leaves $! alone',
    );

    #----------------------------------------------------------------------

    my $notthere2 = catdir( $tdir2, 'notthere' );

    dies_ok(
        sub { IO::Die->chdir($notthere2) },
        'chdir() as normal, to a non-existent directory',
    );
    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re(qr<Chdir:>),
            re(qr<path +\Q$notthere2\E>),
            re(qr<OS_ERROR +>),
            re(qr<EXTENDED_OS_ERROR +>),
        ),
        'exception has the right “goods”',
    );

    is(
        0 + $!,
        5,
        '...and failure leaves $! alone',
    );

    is( _getcwd(), $tdir, '...and it did NOT chdir()' );

    #----------------------------------------------------------------------
    my $tdir_home = catdir( $tdir, 'home' );

    local %ENV = (
        HOME   => $tdir_home,
        LOGDIR => catdir( $tdir, 'logdir' ),
    );
    dies_ok(
        sub { IO::Die->chdir() },
        'chdir() with no args, to a non-existent directory',
    );
    $err = $@;

    like( $err, qr<\Q$tdir_home\E>, 'it tried to chdir() to $ENV{HOME}' );

    is(
        0 + $!,
        5,
        '...and failure leaves $! alone',
    );

    {
        local ( $!, $^E );
        mkdir catdir( $tdir, $_ ) for qw( home logdir );
    }

    ok(
        IO::Die->chdir(),
        'chdir() with no args when $ENV{HOME} is a real directory',
    );

    is( _getcwd(), $tdir_home, '...and it did chdir()' );

    delete $ENV{'HOME'};

    ok(
        IO::Die->chdir(),
        'chdir() with no args when $ENV{LOGDIR} is a real directory',
    );

    is( _getcwd(), catdir( $tdir, 'logdir' ), '...and it did chdir()' );

    delete $ENV{'LOGDIR'};

    #TODO: This doesn’t seem right: “perldoc -f chdir” seems to imply that
    #Perl “happily” does nothing here. “Does nothing” should not be an
    #error state. (cf. https://rt.perl.org/Ticket/Display.html?id=125373)
    dies_ok(
        sub { IO::Die->chdir() },
        'chdir() with no args when neither $ENV{HOME} nor $ENV{LOGDIR} is set',
    );

    is( _getcwd(), catdir( $tdir, 'logdir' ), '...and it did NOT chdir()' );

    return;
}

#cf. https://github.com/rjbs/Test-Deep/issues/26
sub _preload_Test_Deep : Tests(startup) {
    local ( $!, $^E );

    #Can't just pass the :preload flag in to use() above
    #because that will prevent exporting the normal symbols.
    #
    Test::Deep->import(':preload');

    return;
}

sub _getcwd {
    local ( $!, $^E );
    return Cwd::getcwd();
}

sub test_chmod : Tests(12) {
    my ($self) = @_;

    my $dir  = $self->tempdir();
    my $dir2 = $self->tempdir();

    my ( $file, $fh ) = $self->tempfile();

    local $! = 7;

    my $ok = IO::Die->chmod( 0111, $dir );
    is( $ok, 1, 'returns 1 if one path chmod()ed' );
    is( 0777 & ( IO::Die->stat($dir) )[2], 0111, '...and the chmod() worked' );

    is( 0 + $!, 7, '...and it left $! alone' );

    dies_ok(
        sub { IO::Die->chmod( 0222, $dir, $dir2 ) },
        'die()d with >1 path passed',
    );
    is( 0777 & ( IO::Die->stat($dir) )[2], 0111, '...and the chmod() did NOT happen' );

  SKIP: {
        skip 'chmod() on filehandle needs perl >= 5.8.8', 2 if $^V lt v5.8.8;

        $ok = IO::Die->chmod( 0321, $fh );
        is( $ok, 1, 'returns 1 if one filehandle chmod()ed' );
        is( 0777 & ( IO::Die->stat($fh) )[2], 0321, '...and the chmod() worked' );
    }

    IO::Die->close($fh);

    throws_ok(
        sub { IO::Die->chmod( 0456, $fh ) },
        qr<Chmod>,
        'failure when chmod()ing a closed filehandle',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

  TODO: {
        local $TODO = 'https://rt.perl.org/Ticket/Display.html?id=122703';

        my $str = $self->_errno_to_str( Errno::ENOTTY() );

        like(
            $err,
            qr<$str>,
            "exception’s error()",
        ) or diag explain $err;
    }

    throws_ok(
        sub { IO::Die->chmod( 0456, catfile( $dir, 'not_there' ) ) },
        qr<Chmod>,
        'failure when chmod()ing a nonexistent file',
    );
    $err = $@;

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_chown : Tests(13) {
    my ($self) = @_;

    my $dummy = $self->_dummy_user();

  SKIP: {
        skip 'Need to identify a “dummy” user for this test', $self->num_tests() if !$dummy;

        my $nobody_uid = ( getpwnam $dummy )[2];
        my $nobody_gid = ( getgrnam $dummy )[2];

        skip 'Need *nix OS for tests', $self->num_tests() if !$nobody_uid;
        skip 'Must be root!',          $self->num_tests() if $>;

        my $dir  = $self->tempdir();
        my $dir2 = $self->tempdir();

        local $!;

        $! = 7;

        my $ok = IO::Die->chown( $nobody_uid, -1, $dir );
        is( $ok, 1, 'returns 1 if one path chown()ed' );
        is( ( IO::Die->stat($dir) )[4], $nobody_uid, '...and the chown() worked' );

        is( 0 + $!, 7, '...and it left $! alone' );

        my $gid_pre_chown = ( IO::Die->stat($dir) )[5];

        dies_ok(
            sub { IO::Die->chown( -1, $nobody_gid, $dir, $dir2 ) },
            'die()d with >1 path passed',
        );

        is( ( IO::Die->stat($dir) )[5], $gid_pre_chown, '...and the chown() did NOT happen' );
        die "\$! has changed!" if $! != 7;

        my ( $file, $fh ) = $self->tempfile();
        die "\$! has changed!" if $! != 7;

      SKIP: {
            skip 'chown() on file handle needs perl >= 5.8.8', 5 if $^V lt v5.8.8;

            $ok = IO::Die->chown( -1, $nobody_gid, $fh );
            is( $ok,    1, 'returns 1 if one filehandle chown()ed' );
            is( 0 + $!, 7, '...and it left $! alone' );

            is( ( IO::Die->stat($fh) )[5], $nobody_gid, '...and the chown() worked' ) or diag explain [ IO::Die->stat($fh) ];
            die "\$! has changed!" if $! != 7;

            IO::Die->close($fh);
            die "\$! has changed!" if $! != 7;

            throws_ok(
                sub { IO::Die->chown( $>, 0 + $), $fh ) },
                qr<Chown>,
                'failure when chown()ing a closed filehandle',
            );
            is( 0 + $!, 7, '...and it left $! alone' );
        }

        my $err = $@;

      TODO: {
            local $TODO = 'https://rt.perl.org/Ticket/Display.html?id=122703';

            my $str = $self->_errno_to_str( Errno::ENOTTY() );

            like(
                $err,
                qr<$str>,
                "exception’s error()",
            ) or diag explain $err;
        }

        throws_ok(
            sub { IO::Die->chown( $>, 0 + $), catfile( $dir, 'not_there' ) ) },
            qr<Chown>,
            'failure when chown()ing a nonexistent file',
        );
        $err = $@;

        my $str = $self->_errno_to_str( Errno::ENOENT() );

        like(
            $err,
            qr<$str>,
            "exception’s error()",
        ) or diag explain $err;
    }

    return;
}

sub test_stat : Tests(6) {
    my ($self) = @_;

    my $file = $self->tempfile();

    my @stat = stat $file;

    local $! = 7;

    my $scalar = IO::Die->stat($file);
    ok( $scalar, 'stat() in scalar context (with a filename) returns something truthy' );
    is( 0 + $!, 7, '...and it left $! alone' );

    IO::Die->unlink($file);

    is_deeply(
        [ IO::Die->stat( \*_ ) ],
        \@stat,
        'stat() in list context (and using “\*_”) returns the (cached) stat data',
    );

    throws_ok(
        sub { IO::Die->stat($file) },
        qr<Stat>,
        'failure when stat()ing a nonexistent path',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_lstat : Tests(7) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    my $empty_path = catfile( $dir, 'empty' );
    $self->_touch($empty_path);

    symlink 'empty', catfile( $dir, 'symlink' );

    my @symlink_stat = lstat $empty_path;

    #sanity
    die "huh?" if "@symlink_stat" ne join( ' ', stat catfile( $dir, 'symlink' ) );

    my @link_stat_cmp = lstat catfile( $dir, 'symlink' );
    $_ = ignore() for @link_stat_cmp[ 8 .. 10 ];

    local $! = 7;

    my $scalar = IO::Die->lstat( catfile( $dir, 'empty' ) );
    ok( $scalar, 'lstat() in scalar context (with a filename) returns something truthy' );
    is( 0 + $!, 7, '...and it left $! alone' );

    cmp_deeply(
        [ IO::Die->lstat( catfile( $dir, 'symlink' ) ) ],
        \@link_stat_cmp,
        'lstat() (in list context) finds the symlink and stats that, not the referant file',
    );

    die "cmp_deeply() changed \$!" if $! != 7;

    IO::Die->unlink( catfile( $dir, 'symlink' ) );

    #warnings.pm will complain about lstat(_).
    {
        $SIG{'__WARN__'} = sub { };

        cmp_deeply(
            [ IO::Die->lstat( \*_ ) ],
            \@link_stat_cmp,
            'lstat() reads the cache when passed in “\*_”',
        );
    }

    throws_ok(
        sub { IO::Die->lstat( catfile( $dir, 'symlink' ) ) },
        qr<Stat>,
        'failure when lstat()ing a nonexistent symlink',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_link : Tests(6) {
    my ($self) = @_;

    my $dir = $self->tempdir();
    my $filepath = catfile( $dir, 'file' );

    $self->_touch($filepath);

    local $! = 7;

    my $scalar = IO::Die->link( $filepath, catfile( $dir, 'hardlink' ) );
    ok( $scalar, 'link() returns something truthy' );
    is( 0 + $!, 7, '...and it left $! alone' );

    {
        local $!;

        my @orig_file = lstat $filepath;
        my @the_link = lstat catfile( $dir, 'hardlink' );

        is_deeply( \@the_link, \@orig_file, 'new hardlink is the same filesystem node as the old filename' );
    }

    throws_ok(
        sub { IO::Die->link( catfile( $dir, 'notthere' ), catfile( $dir, 'not_a_chance' ) ) },
        qr<Link>,
        'failure when link()ing to a nonexistent file',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_symlink : Tests(7) {
    my ($self) = @_;

    my $dir = $self->tempdir();
    my $filepath = catfile( $dir, 'file' );

    $self->_touch($filepath);

    local $! = 7;

    my $scalar = IO::Die->symlink( "file", catfile( $dir, "symlink" ) );
    ok( $scalar, 'symlink() returns something truthy' );
    is( 0 + $!, 7, '...and it left $! alone' );

    {
        local $!;

        my @orig_file = stat $filepath;
        my @the_link = stat catfile( $dir, "symlink" );

        is_deeply( \@the_link, \@orig_file, 'new symlink points to the same filesystem node as the old filename' );
    }

    $scalar = IO::Die->symlink( "notthere", catfile( $dir, "not_a_chance" ) );
    ok( $scalar, 'symlink() even lets you create a dangling symlink' );

    throws_ok(
        sub { IO::Die->symlink( "notthere", catfile( $dir, "not_a_dir", "not_a_chance" ) ) },
        qr<SymlinkCreate>,
        'failure when creating a symlink() in a nonexistent directory',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_readlink : Tests(10) {
    my ($self) = @_;

    my $dir = $self->tempdir();

    local $!;

    symlink 'haha', catfile( $dir, "mylink" );

    my $file_path = catfile( $dir, "myfile" );
    $self->_touch($file_path);

    $! = 7;

    my $scalar = IO::Die->readlink( catfile( $dir, "mylink" ) );
    is( $scalar, 'haha', 'readlink() returns the link’s value (i.e., destination)' );
    is( 0 + $!,  7,      '...and it left $! alone' );

    for ( catfile( $dir, "mylink" ) ) {
        my $scalar = IO::Die->readlink();
        is( $scalar, 'haha', 'readlink() respects $_ if no parameter is passed' );

        no warnings 'uninitialized';
        dies_ok(
            sub { IO::Die->readlink(undef) },
            '...but if undef is passed, then we do NOT read $_',
        );
        my $err = $@;
        my $str = $self->_errno_to_str( Errno::ENOENT() );

        like(
            $err,
            qr<$str>,
            "exception’s error()",
        ) or diag explain $err;

        is( 0 + $!, 7, '...and it left $! alone' );
    }

    throws_ok(
        sub { IO::Die->readlink( catfile( $dir, "myfile" ) ) },
        qr<SymlinkRead>,
        'failure when reading a symlink that’s actually a file',
    );
    my $err = $@;

    my $str = $self->_errno_to_str( Errno::EINVAL() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    throws_ok(
        sub { IO::Die->readlink( catfile( $dir, "not_there" ) ) },
        qr<SymlinkRead>,
        'failure when reading a nonexistent symlink',
    );
    $err = $@;

    $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_rename : Tests(6) {
    my ($self) = @_;

    my $dir = $self->tempdir();
    my $filepath = catfile( $dir, "file" );

    $self->_touch($filepath);

    local $! = 7;

    my $scalar = IO::Die->rename( catfile( $dir, "file" ), catfile( $dir, "file2" ) );
    ok( $scalar, 'rename() returns something truthy' );
    is( 0 + $!, 7, '...and it left $! alone' );

    {
        local $!;
        ok( ( -e catfile( $dir, "file2" ) ), "rename() actually renamed the file" );
    }

    throws_ok(
        sub { IO::Die->rename( catfile( $dir, "not_there" ), catfile( $dir, "not_at_all" ) ) },
        qr<Rename>,
        'failure when rename()ing a nonexistent file',
    );
    my $err = $@;

    is( 0 + $!, 7, '...and it left $! alone' );

    my $str = $self->_errno_to_str( Errno::ENOENT() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return;
}

sub test_exec : Tests(3) {
    my ($self) = @_;

    my $scratch = $self->tempdir();

    {
        local $SIG{'__WARN__'} = sub { };

        throws_ok(
            sub { IO::Die->exec( catfile( $scratch, "not_there" ) ) },
            qr<Exec>,
            'error type',
        );
    }

    my $err = $@;
    my $str = $self->_errno_to_str( Errno::ENOENT() );
    like( $err, qr<$str>, 'error text' );

  SKIP: {
        skip 'This test requires a *nix OS!', 1 if !`which echo`;

        my $script_name = catfile( $scratch, "ha ha ha" );

        open my $script_fh, '>', $script_name;
        print {$script_fh} "#!/bin/sh$/echo oyoyoy$/";
        chmod 0755, $script_name;    #NB: old perls can’t chmod() a file handle
        close $script_fh;

        pipe my $rfh, my $wfh;
        my $pid = fork || do {
            close $rfh;
            open \*STDOUT, '>&=' . fileno($wfh);
            eval { IO::Die->exec($script_name); };
            diag explain [ 'child', $@ ] if $@;
            exit 1;                  #just in case
        };
        close $wfh;
        my $child_out = do { local $/; <$rfh> };
        close $rfh;

        is( $child_out, "oyoyoy$/", 'exec() handles a command with a space and no args safely' );
    }

    return;
}

sub test_fork : Tests(1) {
    my $pid = IO::Die->fork() || do { exit };
    ok( $pid, 'PID returned' );
    do { local $?; waitpid $pid, 0 };

    return;
}

sub test_fork_failure : Tests(2) {
    my ($self) = @_;

    my $dummy = $self->_dummy_user();

  SKIP: {
        skip 'Need to identify a “dummy” user for this test', $self->num_tests() if !$dummy;

        my $uid = ( getpwnam $dummy )[2];
        my $gid = ( getgrnam $dummy )[2];

        skip 'Need *nix OS for tests!', $self->num_tests() if !$uid;

        eval { require BSD::Resource };
        if ($@) {
            my $err = $@;
            diag $err;
            skip 'Need BSD::Resource', $self->num_tests();
        }

        skip 'Must be root!', $self->num_tests() if $>;

        pipe my $rdr, my $wtr;

        my $pid = fork || do {
            my $at_end = t::IO::Die::Finally->new( sub { exit } );

            $> = $uid;
            $) = $gid;
            $< = $uid;

            BSD::Resource::setrlimit( BSD::Resource::RLIMIT_NPROC(), 3, 3 ) or die "setrlimit()";

            close $rdr;

            my $main_pid = $$;

            local $SIG{'__DIE__'} = sub {
                exit 1 if $$ != $main_pid;
                my $err = shift;
                print {$wtr} "$err$/";
                exit 1;
            };

            IO::Die->fork() while 1;
        };

        close $wtr;
        my $child_out = do { local $/; <$rdr> };
        close $rdr;

        like(
            $child_out,
            qr<Fork>,
            "exception’s type",
        ) or diag explain [$child_out];

        my $str = $self->_errno_to_str( Errno::EAGAIN() );

        like(
            $child_out,
            qr<$str>,
            "exception’s error()",
        ) or diag explain [$child_out];
    }

    return;
}

sub test_pipe : Tests(5) {
    local $! = 7;

    my $ok = IO::Die->pipe( my $rdr, my $wtr );
    ok( $ok, 'pipe() returns something truthy' );
    is( 0 + $!, 7, '...and it left $! alone' );

    isa_ok( $rdr, 'GLOB', 'auto-vivify the reader' );
    isa_ok( $wtr, 'GLOB', 'auto-vivify the writer' );

    my $pid = fork || do {
        close $rdr;
        print $wtr 42;
        exit;
    };

    close $wtr;

    my $from_child = <$rdr>;
    close $rdr;

    do { local $?; waitpid $pid, 0 };

    is( $from_child, 42, '...and the pipe really works' );

    return;
}

sub test_pipe_failure : Tests(2) {
    my ($self) = @_;

    my $dummy = $self->_dummy_user();

  SKIP: {
        skip 'Need to identify a “dummy” user for this test', $self->num_tests() if !$dummy;

        my $uid = ( getpwnam $dummy )[2];
        my $gid = ( getgrnam $dummy )[2];

        skip 'Need *nix OS for tests!', $self->num_tests() if !$uid;
        skip 'Must be root!',           $self->num_tests() if $>;

        pipe my $rdr, my $wtr;

        my $pid = fork || do {
            my $at_end = t::IO::Die::Finally->new( sub { exit } );

            $> = $uid;
            $) = $gid;
            $< = $uid;

            close $rdr;
            alarm 60;
            my @pipes;

            local $SIG{'__DIE__'} = sub {
                my $err = shift;

                close $_ for splice @pipes;

                print {$wtr} "$err$/";

                exit 1;
            };

            while (1) {
                IO::Die->pipe( my $rdr, my $wtr );
                push @pipes, $rdr, $wtr;
            }
        };

        close $wtr;
        my $child_out = do { local $/; <$rdr> };
        close $rdr;

        do { local $?; waitpid $pid, 0 };

        my $str = $self->_errno_to_str( Errno::EMFILE() );

        like(
            $child_out,
            qr<Pipe>,
            "exception’s type",
        ) or diag explain [$child_out];

        like(
            $child_out,
            qr<$str>,
            "exception’s error()",
        ) or diag explain [$child_out];
    }

    return;
}

sub test_fcntl : Tests(5) {
    my ($self) = @_;

    my ( $file, $fh ) = $self->tempfile();

    local $! = 7;

    is(
        IO::Die->fcntl( $fh, &Fcntl::F_GETFL, 0 ),
        do { local $!; fcntl( $fh, &Fcntl::F_GETFL, 0 ) },
        'flags on a “normal” write-only Perl filehandle',
    );

    is( 0 + $!, 7, '...and it left $! alone' );

    {
        local $!;
        sysopen( my $fh2, $file, &Fcntl::O_RDONLY );
        is(
            IO::Die->fcntl( $fh2, &Fcntl::F_SETFL, &Fcntl::O_NONBLOCK ),
            '0 but true',
            'response from fcntl(F_SETFL)',
        );
    }

    close $fh;

    {
        local $SIG{'__WARN__'} = sub { };

        throws_ok(
            sub { IO::Die->fcntl( $fh, &Fcntl::F_GETFL, 0 ) },
            qr<Fcntl>,
            'error from fcntl() on closed filehandle',
        );
    }

    is( 0 + $!, 7, '...and it left $! alone' );

    return;
}

sub test_systell : Tests(3) {
    my ($self) = @_;

    my ( $tempfile, $tfh ) = $self->tempfile();

    is(
        IO::Die->systell($tfh),
        0,
        'systell() is 0 for start of file',
    );

    IO::Die->syswrite( $tfh, 'haha' );

    is(
        IO::Die->systell($tfh),
        4,
        'systell() after writing',
    );

    close $tfh;

    local $SIG{'__WARN__'} = sub { };
    dies_ok(
        sub { IO::Die->systell($tfh) },
        'systell() on a closed filehandle die()s',
    );

    return;
}

sub test_select : Tests(12) {
    my ($self) = @_;

    my ( $rdr, $wtr );
    IO::Die->pipe( $rdr, $wtr );

    local $! = 5;

    my $rdr_mask = $self->_to_bitmask($rdr);
    my $wtr_mask = $self->_to_bitmask($wtr);

    my ( $number, $timeleft ) = IO::Die->select(
        my $rbits = $rdr_mask,
        my $wbits = $wtr_mask,
        undef, 60,
    );

    is( $number, 1, 'correct # returned' );
    like( $timeleft, qr<\A[0-9]+(?:\.[0-9]+)?\z>, 'correct timeleft returned' );

    is( 0 + $!,  5, '$! is left alone' );
    is( 0 + $^E, 5, '$^E is left alone' );

    like( $rbits, qr<\A\0+\z>, 'initial read bits on a single-process pipe' );
    is( $wbits, $wtr_mask, 'initial write bits on a single-process pipe' );

    IO::Die->syswrite( $wtr, 'haha' );

    my $scalar = IO::Die->select(
        $rbits = $rdr_mask,
        $wbits = $wtr_mask,
        undef, undef,
    );

    is( $rbits,  $rdr_mask, 'after the pipe buffer has data, now read bits are different' );
    is( $scalar, 2,         '...as is the number of ready handles (returned as a scalar)' );

    is( $wbits, $wtr_mask, '...but write bits are the same' );

    close $rdr;

    dies_ok(
        sub {
            IO::Die->select(
                $rbits = $rdr_mask,
                undef, undef, undef,
            );
        },
        'exception from select()ing on a closed filehandle',
    );
    my $err = $@;
    like( $err, qr<Select>, '...and the exception type' );

    my $str = $self->_errno_to_str( Errno::EBADF() );

    like(
        $err,
        qr<$str>,
        "exception’s error()",
    ) or diag explain $err;

    return 1;
}

sub test_select_multiplex : Tests(1) {
    my ($self) = @_;

    #----------------------------------------------------------------------
    #NOTE: The below is just to verify that multiplexing works.
    #There are no meaningful assertions because the success/failure
    #is whether the while {} block below ever finishes.

    my ( $pread, $pwrite, $cread, $cwrite );
    IO::Die->pipe( $pread, $cwrite );
    IO::Die->pipe( $cread, $pwrite );

    my $pid = fork || do {
        close $_ for ( $pread, $pwrite );
        print {$cwrite} readline $cread;
        close $_ for ( $cread, $cwrite );
        exit;
    };

    IO::Die->close($_) for ( $cread, $cwrite );

    my $message = "The quick brown fox jumps over the lazy dog." x 1000;
    $message .= "\n";

    my $prmask    = $self->_to_bitmask($pread);
    my $pwmask    = $self->_to_bitmask($pwrite);
    my $sent_back = q<>;
    my $written;
    while ( $sent_back ne $message ) {
        my @ret = IO::Die->select(
            my $rbits = $prmask,
            my $wbits = $written ? undef : $pwmask,
            undef,
            undef,
        );

        if ( !$written && $wbits && ( $wbits & $pwmask ) eq $pwmask ) {
            IO::Die->print( $pwrite, $message );
            IO::Die->close($pwrite);
            $written = 1;
        }
        elsif ( $rbits && $rbits ne "\0" ) {
            local ( $!, $^E );
            IO::Die->read( $pread, $sent_back, 200, length $sent_back );
        }
    }

    IO::Die->close($pread);

    do { local $?; waitpid $pid, 0 };

    #----------------------------------------------------------------------

    ok 1;    #for Test::Class - just so we assert *something*

    return;
}

sub test_socket : Tests(5) {
    my ($self) = @_;

    my $socket = IO::Handle->new();

    local $! = 7;

    is( IO::Die->socket( $socket, &Socket::PF_UNIX, &Socket::SOCK_STREAM, &Socket::PF_UNSPEC ), 1, "socket creation ok" );

    is( 0 + $!, 7, '...and leaves $! alone' );

    local $@;

    for my $domain (&Socket::AF_INET) {
        eval { IO::Die->socket( my $socket, $domain, &Socket::SOCK_STREAM, -1 ); };
        my $err = $@;

        cmp_deeply(
            $err,
            all(
                re($domain),
                re('SocketOpen'),
                re('-1'),
            ),
            "socket() creation failure exception is right type and contains domain and protocol",
        );

        is( 0 + $!, 7, '...and leaves $! alone' );
    }

    for my $type (&Socket::SOCK_STREAM) {
        eval { IO::Die->socket( my $socket, &Socket::AF_INET, $type, -1 ); };
        my $err = $@;

        cmp_deeply(
            $err,
            all(
                re($type),
                re('SocketOpen'),
                re('-1'),
            ),
            "socket() creation failure exception is right type and contains socket type and protocol",
        );
    }

    return;
}

sub test_send_recv : Tests(6) {

    socketpair( my $skt1, my $skt2, &Socket::PF_UNIX, &Socket::SOCK_STREAM, &Socket::PF_UNSPEC );

    local $! = 7;
    IO::Die->send( $skt1, 'msg1', &Socket::MSG_DONTROUTE );
    IO::Die->recv( $skt2, my $msg, 4, 0 );
    is( $msg,   'msg1', 'send()/recv()' );
    is( 0 + $!, 7,      '...and leaves $! alone' );

    close $skt1;

    local $@;
    eval {
        local $SIG{'__WARN__'} = sub { };
        IO::Die->send( $skt1, 'msg2', &Socket::MSG_DONTROUTE );
    };
    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re(qr<SocketSend>),
            re(&Socket::MSG_DONTROUTE),
        ),
        'send() failure',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    close $skt2;

    local $@;
    eval {
        local $SIG{'__WARN__'} = sub { };
        IO::Die->recv( $skt2, my $n, &Socket::MSG_DONTROUTE );
    };
    $err = $@;

    cmp_deeply(
        $err,
        all(
            re(qr<SocketReceive>),
            re(0),
        ),
        'recv() failure',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    return;
}

sub test_socketpair : Tests(11) {
    my ($self) = @_;

    local $! = 7;

    is( IO::Die->socketpair( my $skt1, my $skt2, &Socket::PF_UNIX, &Socket::SOCK_STREAM, &Socket::PF_UNSPEC ), 1, "socketpair creation ok" );

    is( 0 + $!, 7, '...and leaves $! alone' );

    {
        local $!;

        is(
            syswrite( $skt1, '424242' ),
            6,
            'write to socket 1',
        );

        is(
            sysread( $skt2, my $buf, 6 ),
            6,
            'read from socket 2',
        );

        is( $buf, '424242', 'sent over socket pair 1 -> 2 ok' );

        is(
            syswrite( $skt2, '565656' ),
            6,
            'write to socket 2',
        );

        is(
            sysread( $skt1, $buf, 6, length $buf ),
            6,
            'read from socket 1',
        );

        is( $buf, '424242565656', 'sent over socket pair 2 -> 1 ok' );
    }

    local $@;

    for my $domain (&Socket::AF_INET) {
        eval { IO::Die->socketpair( $skt1, $skt2, $domain, &Socket::SOCK_STREAM, -1 ); };
        my $err = $@;

        cmp_deeply(
            $err,
            all(
                re($domain),
                re('SocketPair'),
                re('-1'),
            ),
            "socketpair() creation failure exception is right type and contains domain and protocol",
        );

        is( 0 + $!, 7, '...and leaves $! alone' );
    }

    for my $type (&Socket::SOCK_STREAM) {
        eval { IO::Die->socketpair( $skt1, $skt2, &Socket::AF_INET, $type, -1 ); };
        my $err = $@;

        cmp_deeply(
            $err,
            all(
                re($type),
                re('SocketPair'),
                re('-1'),
            ),
            "socketpair() creation failure exception is right type and contains socket type and protocol",
        );
    }

    return;
}

sub _bind_free_port {
    my ($socket) = @_;

    my $port;

    local $@;

    alarm 60;
    while (1) {
        $port = int( 60000 * rand ) + 1024;

        my $iaddr = Socket::inet_aton('127.0.0.1');

        my $sockname = Socket::pack_sockaddr_in( $port, $iaddr );
        my $ok;
        eval { $ok = IO::Die->bind( $socket, $sockname ); };
        last if $ok;
    }

    alarm 0;

    return $port;
}

sub test_socket_client : Tests(4) {
    my $proto = getprotobyname('tcp');

    my $got_USR1 = 0;
    local $SIG{'USR1'} = sub { $got_USR1++ };

    pipe my $p_rd, my $c_wr;

    local $@;
    local $! = 7;

    my $iaddr = Socket::inet_aton('127.0.0.1');

    my $bad_sockname = Socket::pack_sockaddr_in( 1234, $iaddr );
    eval { IO::Die->connect( \*STDIN, $bad_sockname ) };
    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re('SocketConnect'),
            re(qr<\Q$bad_sockname\E>),
        ),
        'connect() failure',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    my $child_pid = IO::Die->fork() or do {
        close $p_rd;

        my $sent_USR1;
        my $at_end = t::IO::Die::Finally->new( sub { $sent_USR1 ||= kill 'USR1', getppid() } );

        eval {
            IO::Die->socket( my $srv_fh, &Socket::PF_INET, &Socket::SOCK_STREAM, $proto );

            my $port = _bind_free_port($srv_fh);
            IO::Die->print( $c_wr, Socket::pack_sockaddr_in( $port, $iaddr ) );
            IO::Die->close($c_wr);

            IO::Die->listen( $srv_fh, 2 );

            $sent_USR1 = kill 'USR1', getppid();

            IO::Die->accept( my $redshirt_fh, $srv_fh );
        };
        if ($@) {
            my $err = $@;
            diag explain [ 'child', $err ];
            die $err;
        }

        exit;
    };

    IO::Die->close($c_wr);

    IO::Die->read( $p_rd, my $sockname, 1024 );

    my $at_end = t::IO::Die::Finally->new(
        sub {
            local $?;
            waitpid $child_pid, 0;
        }
    );

    eval {
        sleep 1 while !$got_USR1;

        IO::Die->socket( my $cl_fh, &Socket::PF_INET, &Socket::SOCK_STREAM, $proto );

        $! = 7;

        ok(
            IO::Die->connect( $cl_fh, $sockname ),
            'connect() succeeds',
        );

        is( $! + 0, 7, '...and leaves $! alone' );
    };
    if ($@) {
        my $err = $@;
        diag explain $err;
        die $err;
    }

    return;
}

sub test_socket_server : Tests(24) {
    my ($self) = @_;

    my $proto = getprotobyname('tcp');

    my $got_USR1 = 0;
    local $SIG{'USR1'} = sub { $got_USR1++ };

    pipe my $c_rd, my $p_wr;

    my $child_pid = IO::Die->fork() or do {
        IO::Die->close($p_wr);
        eval {
            sleep 1 while !$got_USR1;

            IO::Die->socket( my $cl_fh, &Socket::PF_INET, &Socket::SOCK_STREAM, $proto );

            IO::Die->read( $c_rd, my $sockname, 1024 );
            IO::Die->close($c_rd);

            IO::Die->connect( $cl_fh, $sockname );
            IO::Die->read( $cl_fh, my $buf, 2048 );
            IO::Die->print( $cl_fh, 'from client' );
        };
        diag explain [ 'child err', $@ ] if $@;

        exit;
    };

    IO::Die->close($c_rd);

    my $sent_USR1;

    my $at_end = t::IO::Die::Finally->new(
        sub {
            $sent_USR1 ||= IO::Die->kill( 'USR1', $child_pid );
            do { local $?; waitpid $child_pid, 0 };
        }
    );

    local ( $@, $!, $^E );
    $! = 7;

    IO::Die->socket( my $srv_fh, &Socket::PF_INET, &Socket::SOCK_STREAM, $proto );

    eval { IO::Die->setsockopt( $srv_fh, -1, &Socket::SO_DEBUG, 7 ) };
    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re('SocketSetOpt'),
            re(-1),
            re(&Socket::SO_DEBUG),
            re(7),
        ),
        'setsockopt() failure',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    #NOTE: The specific options that are set and read here are finicky
    #among different OSes. The example below is in “perldoc -f setsockopt”,
    #which hopefully means it’s generic enough to work just about anywhere.

    ok(
        eval { IO::Die->setsockopt( $srv_fh, &Socket::IPPROTO_TCP, &Socket::TCP_NODELAY, 1 ) },
        'setsockopt() per perldoc perlipc',
    ) or diag explain $@;

    is( 0 + $!, 7, '...and leaves $! alone' );

    my $sockopt = eval { IO::Die->getsockopt( $srv_fh, &Socket::IPPROTO_TCP, &Socket::TCP_NODELAY ) };
    $err = $@;

    like(
        $sockopt,
        qr<[^\0]>,
        'getsockopt(): one of the bytes of SOL_SOCKET/SO_BROADCAST is nonzero',
      )
      or do {
        local $Data::Dumper::Useqq = 1;
        diag Data::Dumper::Dumper( $sockopt, $err );
      };

    is( 0 + $!, 7, '...and leaves $! alone' );

    eval { IO::Die->bind( $srv_fh, '@@@@' ) };
    $err = $@;

    cmp_deeply(
        $err,
        all(
            re('SocketBind'),
            re(qr<@@@@>),
        ),
        'bind() failure',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    my $iaddr = Socket::inet_aton('127.0.0.1');

    my $port = _bind_free_port($srv_fh);
    IO::Die->print( $p_wr, Socket::pack_sockaddr_in( $port, $iaddr ) );
    IO::Die->close($p_wr);

    is( 0 + $!, 7, 'successful bind() leaves $! alone' );

    eval { IO::Die->listen( \*STDERR, -1 ) };
    $err = $@;

    cmp_deeply(
        $err,
        all(
            re('SocketListen'),
            re(qr<-1>),
        ),
        'listen() failure',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    ok(
        IO::Die->listen( $srv_fh, 2 ),
        'listen() per perldoc perlipc',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    $sent_USR1 = IO::Die->kill( 'USR1', $child_pid );

    my $paddr = IO::Die->accept( my $cl_fh, $srv_fh );

    isa_ok( $cl_fh, 'GLOB', 'auto-vivify the filehandle on accept()' );

    ok(
        $paddr,
        'accept() per perldoc perlipc',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    my ( $accept_port, $accept_iaddr ) = Socket::unpack_sockaddr_in($paddr);
    like(
        $accept_port,
        qr<\A[1-9][0-9]*\z>,
        'accept() port',
    );

    is( $accept_iaddr, Socket::inet_aton('127.0.0.1'), 'accept() address' );

    is(
        IO::Die->syswrite( $cl_fh, "from server\n" ),
        12,
        'print() to connect() socket',
    );

    ok(
        IO::Die->shutdown( $cl_fh, &Socket::SHUT_WR ),
        'shutdown() writing',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    IO::Die->read( $cl_fh, my $from_client, 2048 );
    is( $from_client, 'from client', 'read from connect() socket' );

    #NB: NetBSD doesn't indicate an error when you try to
    #shutdown( $cl_fh, &Socket::SHUT_WR ) a second time. (Bug?)
    #cf. https://rt.perl.org/Ticket/Display.html?id=125465
    #
    my ( undef, $fh ) = $self->tempfile();
    eval { IO::Die->shutdown( $fh, &Socket::SHUT_WR ) };
    $err = $@;

    cmp_deeply(
        $err,
        all(
            re('SocketShutdown'),
        ),
        'shutdown() failure',
    );

    is( 0 + $!, 7, '...and leaves $! alone' );

    return;
}

sub test_CREATE_ERROR : Test(1) {
    my $self = shift;

    local $SIG{'__WARN__'} = sub { };

    local $@;
    eval { IO::Die::Subclass->read( \*STDOUT, my $fail, 123 ); };
    my $err = $@;

    cmp_deeply(
        $err,
        {
            type  => 'Read',
            attrs => Test::Deep::Isa('HASH'),
        },
        '_CREATE_ERROR can override the default exception',
    ) or diag explain $err;

    return;
}

sub test_kill_reject_multiple : Tests(1) {
    my $pid1 = fork || do { sleep 999 };
    my $pid2 = fork || do { sleep 999 };

    dies_ok(
        sub { IO::Die->kill( 'TERM', $pid1, $pid2 ) },
        'kill() rejected multiple PIDs',
    );

    kill 'TERM', $pid1, $pid2;

    return;
}

sub test_kill : Tests(8) {
    my ($self) = @_;

    my $dummy = $self->_dummy_user();

  SKIP: {
        skip 'Need to identify a “dummy” user for this test', $self->num_tests() if !$dummy;

        my $nobody_uid = ( getpwnam $dummy )[2];
        my $nobody_gid = ( getgrnam $dummy )[2];

        skip 'Need *nix OS for tests', $self->num_tests() if !$nobody_uid;
        skip 'Must be root!',          $self->num_tests() if $>;

        my $pid = fork || do { sleep 999 };

        local ( $!, $^E );

        $!  = 5;
        $^E = 5;

        my $ret = IO::Die->kill( 'TERM', $pid );

        is( $ret,    1, 'kill() returned as it should' );
        is( 0 + $!,  5, '...and it didn’t affect $!' );
        is( 0 + $^E, 5, '...and it didn’t affect $^E' );

        my $parent_pid = $$;

        pipe my $rdr, my $wtr;

        #DragonflyBSD allows an unprivileged (?) subprocess
        #to send SIGTERM to a root-owned parent process. (?!?!?)
        my $got_SIGTERM;
        local $SIG{'TERM'} = sub { $got_SIGTERM++ };

        my $parasite_pid = fork || do {
            my $at_end = t::IO::Die::Finally->new( sub { exit } );

            eval {
                close $rdr;

                $> = $nobody_uid;
                $) = $nobody_gid;
                $< = $nobody_uid;

                $!  = 5;
                $^E = 5;

                IO::Die->kill( 'TERM', $parent_pid );
            };
            if ($@) {
                print {$wtr} join( $/, 0 + $!, 0 + $^E, $@ );
            }
        };

        close $wtr;
        my @res = split m<$/>, do { local $/; <$rdr> };
        close $rdr;

        do { local $?; waitpid $parasite_pid, 0 };

        if ($got_SIGTERM) {
            skip "$^O: Unprivileged child process can SIGTERM a root-owned parent process?!?", 5;
        }

        is( $res[0], 5, 'kill() doesn’t affect $! on failure' );
        is( $res[1], 5, 'kill() doesn’t affect $^E on failure' );

        like( $res[2], qr<Kill>,        'kill() as user on a root-owned process' );
        like( $res[2], qr<TERM>,        'the signal is in the error' );
        like( $res[2], qr<$parent_pid>, 'the PID is in the error' );
    }

    return;
}

sub test_binmode : Tests(9) {
    my ($self) = @_;

    ( my $path, my $fh ) = $self->tempfile();

    open my $rfh, '<', $path;

    open my $rfh2, '<', $path;
    close $rfh2;

    my $err;

    local ( $!, $^E );

    $!  = 5;
    $^E = 5;

    ok(
        IO::Die->binmode($rfh),
        'binmode() returns true on success',
    );

    is( 0 + $!,  5, 'binmode() success left $! alone' );
    is( 0 + $^E, 5, 'binmode() success left $^E alone' );

    local $@;
    eval {
        local $SIG{'__WARN__'} = sub { };
        IO::Die->binmode($rfh2);
    };
    $err = $@;

    like( $err, qr<Binmode>, 'error type in error' );
    like( $err, qr<:raw>,    'default layer is in error' );
    like( $err, qr<layer>,   '...and it’s called “layer”' );

    my $errstr = do { local $! = Errno::EBADF(); "$!" };
    like( $err, qr<$errstr>, '...and the error is as expected' );

    is( 0 + $!,  5, 'binmode() failure left $! alone' );
    is( 0 + $^E, 5, 'binmode() failure left $^E alone' );

    return;
}

sub test_fileno : Tests(4) {
    my ($self) = @_;

    my ( $tempfile, $tfh ) = $self->tempfile();
    close $tfh;

    my $stdout_fileno = fileno \*STDOUT;
    local $! = 7;
    is(
        IO::Die->fileno( \*STDOUT ),
        $stdout_fileno,
        'fileno() works',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    local $@;
    eval { IO::Die->fileno($tfh) };
    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re(qr<Fileno>),
        ),
        'exception on invalid fileno()',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    return;
}

sub test_utime : Tests(7) {
    my ($self) = @_;

    my ( $tempfile,  $tfh )  = $self->tempfile();
    my ( $tempfile2, $tfh2 ) = $self->tempfile();

    local $! = 7;

    local $@;
    eval { IO::Die->utime( 100, 101, $tfh, $tfh2 ) };
    ok( $@, 'utime() with multiple “thingies”' );
    is( 0 + $!, 7, '...and leaves $! alone' );

    IO::Die->close($tfh2);

    is(
        IO::Die->utime( 200, 201, $tempfile ),
        1,
        'utime() with 1 filename',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    my @stat = IO::Die->stat($tfh);
    is_deeply(
        [ @stat[ 8, 9 ] ],
        [ 200, 201 ],
        'file times (from filehandle) after filename rename',
    );

    local $@;
    eval { IO::Die->utime( 300, 301, catfile( $tempfile, 'not', 'there' ) ) };
    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re(qr<Utime>),
        ),
        'exception on invalid path',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    return;
}

sub test_flock : Tests(4) {
    my ($self) = @_;

    my ( $tempfile, $tfh ) = $self->tempfile();

    local $! = 7;

    ok(
        IO::Die->flock( $tfh, &Fcntl::LOCK_EX ),
        'flock()',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    IO::Die->close($tfh);

    local $@;
    eval {
        local $SIG{'__WARN__'} = sub { };
        IO::Die->flock( $tfh, &Fcntl::LOCK_UN );
    };
    my $err = $@;

    cmp_deeply(
        $err,
        all(
            re(qr<Flock>),
            re(&Fcntl::LOCK_UN),
        ),
        'exception from invalid flock()',
    );
    is( 0 + $!, 7, '...and leaves $! alone' );

    return;
}

#----------------------------------------------------------------------

sub zzzzzzz_sanity : Test(1) {
    ok 1, 'This just ensures that STDOUT has been put back.';

    return;
}

sub _overwrite_stdout {
    my ( $self, $new_stdout ) = @_;

    open my $real_stdout_fh, '>&=', fileno select;

    select $new_stdout;    ## no critic qw(ProhibitOneArgSelect)

    return $real_stdout_fh;
}

package IO::Die::Subclass;

use strict;

use base 'IO::Die';

sub _CREATE_ERROR {
    my ( $NS, $type, @attrs ) = @_;

    return {
        type  => $type,
        attrs => {@attrs},
    };
}

package t::IO::Die::Finally;

sub new {
    my ( $class, $todo_cr ) = @_;

    return bless [$todo_cr], $class;
}

sub DESTROY {
    my ($self) = @_;
    return $self->[0]->();
}

1;
