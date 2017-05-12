package IO::Any;

use warnings;
use strict;
use utf8;

our $VERSION = '0.09';

use Carp 'confess';
use Scalar::Util 'blessed';
use IO::String;
use IO::File;
use IO::AtomicFile;
use File::Spec;
use Fcntl qw(:flock);
use List::MoreUtils qw(none any);

sub new {
    my $class = shift;
    my $what  = shift;
    my $how   = shift || '<';
    my $opt   = shift || {};
    confess 'too many arguments'
        if @_;

    confess '$what is missing'
        if not defined $what;

    confess 'expecting hash ref'
        if ref $opt ne 'HASH';
    foreach my $key (keys %$opt) {
        confess 'unknown option '.$key
            if (none { $key eq $_ } qw(atomic LOCK_SH LOCK_EX LOCK_NB));
    }

    my ($type, $proper_what) = $class->_guess_what($what);


    if ($type eq 'string') { return IO::String->new($proper_what) }
    if ($type eq 'file')   {
            my $fh = $opt->{'atomic'} ? IO::AtomicFile->new() : IO::File->new();
            $fh->open($proper_what, $how)
                or confess 'error opening file "'.$proper_what.'" - '.$!;

            # locking if requested
            if ($opt->{'LOCK_SH'} or $opt->{'LOCK_EX'}) {
                flock($fh,
                    ($opt->{'LOCK_SH'} ? LOCK_SH : 0)
                    | ($opt->{'LOCK_EX'} ? LOCK_EX : 0)
                    | ($opt->{'LOCK_NB'} ? LOCK_NB : 0)
                ) or confess 'flock failed - '.$!;
            }

            return $fh;
        }
    if ($type eq 'iofile')   { return $proper_what }
    if ($type eq 'iostring') { return $proper_what }
    if ($type eq 'http')     { die 'no http support yet :-|' }
}

sub _guess_what {
    my $class = shift;
    my $what  = shift;

    if (!blessed($what)) { }            # not blessed, do nothing
    elsif ($what->isa('Path::Class::File')) { $what = $what->stringify }
    elsif (any { $what->isa($_) } qw(IO::File IO::AtomicFile IO::Uncompress::Bunzip2)) {
            confess 'passed unopened IO::File'
                if not $what->opened;
            return ('iofile', $what);
        }
    elsif ($what->isa('IO::String')) { return ('iostring', $what) }
    else { confess 'no support for '.blessed($what) };

    my $ref_what = ref($what);
    if ($ref_what eq 'ARRAY')     { return ('file', File::Spec->catfile(@{$what})) }
    elsif ($ref_what eq 'SCALAR') { return ('string', $what) }
    elsif ($ref_what eq '')       {} # do nothing here if not reference
    else { confess 'no support for ref '.(ref $what) }

    # check for typeglobs
    if ((ref \$what eq 'GLOB') and (my $fh = *{$what}{IO})) {
        return ('iofile', $fh);
    }

    if ($what =~ m{^file://(.+)$}) { return ('file', $1) }              # local file
    if ($what =~ m{^https?://})    { return ('http', $what) }           # http link
    if ($what =~ m{^<})            { return ('string', $what) }         # xml string
    if ($what =~ m(^{))            { return ('string', $what) }         # json string
    if ($what =~ m{^\[})           { return ('string', $what) }         # json string
    if ($what =~ m{\n[\s\w]})      { return ('string', $what) }         # multi-line string
    if ($what eq '')               { return ('string', '') }            # empty string
                                   { return ('file', $what) }           # default is filename
}

sub read {
    my $class = shift;
    my $what  = shift;
    my $opt   = shift;
    confess 'too many arguments'
        if @_;

    return $class->new($what, '<', $opt);
}

sub write {
    my $class = shift;
    my $what  = shift;
    my $opt   = shift;
    confess 'too many arguments'
        if @_;

    return $class->new($what, '>', $opt);
}

sub slurp {
    my $class = shift;
    my $what  = shift;
    my $opt   = shift;
    confess 'too many arguments'
        if @_;

    my $fh = $class->read($what, $opt);

    # use event loop when AnyEvent is loaded (skip IO::String, doesn't work and makes no sense)
    # not supported under MSWin32
    if ($INC{'AnyEvent.pm'} and not $fh->isa('IO::String') and ($^O ne 'MSWin32')) {
        eval 'use AnyEvent::Handle'
            if not $INC{'AnyEvent/Handle.pm'};
        my $eof = AnyEvent->condvar;
        my $content = '';
        my $hdl = AnyEvent::Handle->new(
            fh      => $fh,
            on_read => sub {
                $content .= delete $_[0]->{'rbuf'};
            },
            on_eof  => sub {
                $eof->send;
            },
            on_error => sub {
                my ($hdl, $fatal, $msg) = @_;
                $hdl->destroy;
                $eof->croak($msg);
            }
        );

        $eof->recv;
        $hdl->destroy;
        close $fh;
        return $content;
    }

    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
}

sub spew {
    my $class = shift;
    my $what  = shift;
    my $data  = shift;
    my $opt   = shift;
    confess 'too many arguments'
        if @_;

    # "parade" to allow safe locking
    my $fh = $class->new($what, '+>>', $opt);
    $fh->seek(0,0);
    $fh->truncate(0);

    # use event loop when AnyEvent is loaded (skip IO::String, doesn't work and makes no sense)
    if ($INC{'AnyEvent.pm'} and not $fh->isa('IO::String')) {
        eval 'use AnyEvent::Handle'
            if not $INC{'AnyEvent/Handle.pm'};

        my $eof = AnyEvent->condvar;
        my $hdl = AnyEvent::Handle->new(
            fh       => $fh,
            on_drain => sub {
                $eof->send;
            },
            on_error => sub {
                my ($hdl, $fatal, $msg) = @_;
                $hdl->destroy;
                $eof->croak($msg);
            }
        );

        $hdl->push_write($data);

        $eof->recv;
        $hdl->destroy;
        close $fh;
        return;
    }

    print $fh $data;
    $fh->close || confess 'failed to close file - '.$!;
    return;
}

1;


__END__

=encoding utf8

=head1 NAME

IO::Any - open anything

=head1 SYNOPSIS

    # NOTE commented out lines doesn't work (yet)
    use IO::Any;

    $fh = IO::Any->read('filename');
    $fh = IO::Any->read('file://var/log/syslog');
    #$fh = IO::Any->read('http://search.cpan.org/');
    #$fh = IO::Any->read('-');
    $fh = IO::Any->read(['folder', 'other-folder', 'filename']);
    $fh = IO::Any->read('folder');
    $fh = IO::Any->read("some text\nwith more lines\n");
    $fh = IO::Any->read(\"some text\nwith more lines\n");
    $fh = IO::Any->read('{"123":[1,2,3]}');
    $fh = IO::Any->read('<root><element>abc</element></root>');
    $fh = IO::Any->read(*DATA);
    $fh = IO::Any->read(IO::String->new("cba"));
    #$fh = IO::Any->read($object_with_toString_method);

    $fh = IO::Any->write('filename');
    $fh = IO::Any->write('file://var/log/syslog');
    #$fh = IO::Any->write('-');
    $fh = IO::Any->write(['folder', 'filename']);
    #$fh = IO::Any->write('=');
    my $string;
    $fh = IO::Any->write(\$string);

    my $content = IO::Any->slurp(['folder', 'filename']);
    IO::Any->spew(['folder2', 'filename'], $content);

    perl -MIO::Any -le 'print IO::Any->slurp("/etc/passwd")'
    perl -MIO::Any -le 'IO::Any->spew("/tmp/timetick", time())'

=head1 DESCRIPTION

The aim is to provide read/write anything. The module tries to guess
C<$what> the "anything" is based on some rules. See L</new> method Pod for
examples and L</new> and L</_guess_what> code for the implementation.

There are two methods L</slurp> and L</spew> to read/write whole C<$what>.

=head1 MOTIVATION

The purpose is to be able to use L<IO::Any> in other modules that needs
to read or write data. The description for an argument could be - pass
anything that L<IO::Any> accepts as argument - GLOBs, L<IO::File>,
L<Path::Class::File>, L<IO::AtomicFile>, L<IO::String>, pointers to scalar
and pointer to array (array elements are passed to L<File::Spec/catfile>
as portable file addressing).

First time I've used L<IO::Any> for L<JSON::Util> where for the functions
to encode and decode needs to read/write data.

=head1 METHODS

=head2 new($what, $how, $options)

Open C<$what> in C<$how> mode.

C<$what> can be:

		'filename'                => [ 'file' => 'filename' ],
		'folder/filename'         => [ 'file' => 'folder/filename' ],
		'file:///folder/filename' => [ 'file' => '/folder/filename' ],
		[ 'folder', 'filename' ]  => [ 'file' => File::Spec->catfile('folder', 'filename') ],
		'http://a/b/c'            => [ 'http' => 'http://a/b/c' ],
		'https://a/b/c'           => [ 'http' => 'https://a/b/c' ],
		'{"123":[1,2,3]}'         => [ 'string' => '{"123":[1,2,3]}' ],
		'[1,2,3]'                 => [ 'string' => '[1,2,3]' ],
		'<xml></xml>'             => [ 'string' => '<xml></xml>' ],
		"a\nb\nc\n"               => [ 'string' => "a\nb\nc\n" ],
		*DATA                     => [ 'file' => *{DATA}{IO} ],

Returns filehandle. L<IO::String> for 'string', L<IO::File> for 'file'.
'http' not implemented yet.

Here are available C<%$options> options:

    atomic    true/false if the file operations should be done using L<IO::AtomicFile> or L<IO::File>
    LOCK_SH   lock file for shared access
    LOCK_EX   lock file for exclusive
    LOCK_NB   lock file non blocking (will throw an excpetion if file is
                  already locked, instead of blocking the process)

=head2 _guess_what

Returns ($type, $what). $type can be:

    file
    string
    http
    iostring
    iofile

C<$what> is normalized path that can be used for IO::*.

=head2 read($what)

Same as C<< IO::Any->new($what, '<'); >> or C<< IO::Any->new($what); >>.

=head2 write($what)

Same as C<< IO::Any->new($what, '>'); >>

=head2 slurp($what)

Returns content of C<$what>.

If L<AnyEvent> is loaded then uses event loop to read the content.

=head2 spew($what, $data, $opt)

Writes C<$data> to C<$what>.

If L<AnyEvent> is loaded then uses event loop to write the content.

=head1 SEE ALSO

L<IO::All>, L<File::Spec>, L<Path::Class>

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 CONTRIBUTORS

The following people have contributed to the Sys::Path by committing their
code, sending patches, reporting bugs, asking questions, suggesting useful
advice, nitpicking, chatting on IRC or commenting on my blog (in no particular
order):

    SREZIC [...] cpan.org
    Alexandr Ciornii
    Gabor Szabo
    Przemek Wesołek
    Slaven Rezić

=head1 BUGS

Please report any bugs or feature requests to C<bug-io-any at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO-Any>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Any


You can also look for information at:

=over 4

=item * GitHub: issues

L<http://github.com/jozef/IO-Any/issues>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Any>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO-Any>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO-Any>

=item * Search CPAN

L<http://search.cpan.org/dist/IO-Any>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of IO::Any
