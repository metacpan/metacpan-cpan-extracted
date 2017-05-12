package Localizer::Scanner::Perl;
use strict;
use warnings;
use utf8;
use 5.010_001;

use constant NUL  => 0;
use constant BEG  => 1;
use constant PAR  => 2;
use constant HERE => 10;
use constant QUO1 => 3;
use constant QUO2 => 4;
use constant QUO3 => 5;
use constant QUO4 => 6;
use constant QUO5 => 7;
use constant QUO6 => 8;
use constant QUO7 => 9;

sub new {
    my $class = shift;
    bless { }, $class;
}

sub scan {
    my($self, $result, $filename, $data) = @_;
    $self->_walker($data, $result, $filename);
    return $result;
}

sub scan_file {
    my ($self, $result, $filename) = @_;
    open my $fh, '<:encoding(utf-8)', $filename
        or die "Cannot open file '$filename' for reading: $!";
    my $data = do { local $/; <$fh> };
    return $self->scan($result, $filename, $data);
}

# Imported from Locale::Maketext::Extract::Plugin::Perl
sub _walker {
    my $self = shift;
    local $_ = shift;
    my ($result, $filename) = @_;

    local $SIG{__WARN__} = sub { die @_ };

    # Perl code:
    my ( $state, $line_offset, $str, $str_part, $vars, $quo, $heredoc )
        = ( 0, 0 );
    my $orig = 1 + ( () = ( ( my $__ = $_ ) =~ /\n/g ) );

PARSER: {
        $_ = substr( $_, pos($_) ) if ( pos($_) );
        my $line = $orig - ( () = ( ( my $__ = $_ ) =~ /\n/g ) );

        # various ways to spell the localization function
        $state == NUL
            && m/\b(translate|maketext|gettext|__?|loc(?:ali[sz]e)?|l|x)/gc
            && do { $state = BEG; redo };
        $state == BEG && m/^([\s\t\n]*)/gc && redo;

        # begin ()
        $state == BEG
            && m/^([\S\(])\s*/gc
            && do { $state = ( ( $1 eq '(' ) ? PAR : NUL ); redo };

        # concat
        $state == PAR
            && defined($str)
            && m/^(\s*\.\s*)/gc
            && do { $line_offset += ( () = ( ( my $__ = $1 ) =~ /\n/g ) ); redo };

        # str_part
        $state == PAR && defined($str_part) && do {
            if ( ( $quo == QUO1 ) || ( $quo == QUO5 ) ) {
                $str_part =~ s/\\([\\'])/$1/g
                    if ($str_part);    # normalize q strings
            }
            elsif ( $quo != QUO6 ) {
                $str_part =~ s/(\\(?:[0x]..|c?.))/"qq($1)"/eeg
                    if ($str_part);    # normalize qq / qx strings
            }
            $str .= $str_part;
            undef $str_part;
            undef $quo;
            redo;
        };

        # begin or end of string
        $state == PAR && m/^(\')/gc && do { $state = $quo = QUO1; redo };
        $state == QUO1 && m/^([^'\\]+)/gc   && do { $str_part .= $1; redo };
        $state == QUO1 && m/^((?:\\.)+)/gcs && do { $str_part .= $1; redo };
        $state == QUO1 && m/^\'/gc && do { $state = PAR; redo };

        $state == PAR && m/^\"/gc && do { $state = $quo = QUO2; redo };
        $state == QUO2 && m/^([^"\\]+)/gc   && do { $str_part .= $1; redo };
        $state == QUO2 && m/^((?:\\.)+)/gcs && do { $str_part .= $1; redo };
        $state == QUO2 && m/^\"/gc && do { $state = PAR; redo };

        $state == PAR && m/^\`/gc && do { $state = $quo = QUO3; redo };
        $state == QUO3 && m/^([^\`]*)/gc && do { $str_part .= $1; redo };
        $state == QUO3 && m/^\`/gc && do { $state = PAR; redo };

        $state == PAR && m/^qq\{/gc && do { $state = $quo = QUO4; redo };
        $state == QUO4 && m/^([^\}]*)/gc && do { $str_part .= $1; redo };
        $state == QUO4 && m/^\}/gc && do { $state = PAR; redo };

        $state == PAR && m/^q\{/gc && do { $state = $quo = QUO5; redo };
        $state == QUO5 && m/^([^\}]*)/gc && do { $str_part .= $1; redo };
        $state == QUO5 && m/^\}/gc && do { $state = PAR; redo };

        # find heredoc terminator, then get the
        #heredoc and go back to current position
        $state == PAR
            && m/^<<\s*\'/gc
            && do { $state = $quo = QUO6; $heredoc = ''; redo };
        $state == QUO6 && m/^([^'\\\n]+)/gc && do { $heredoc .= $1; redo };
        $state == QUO6 && m/^((?:\\.)+)/gc  && do { $heredoc .= $1; redo };
        $state == QUO6
            && m/^\'/gc
            && do { $state = HERE; $heredoc =~ s/\\\'/\'/g; redo };

        $state == PAR
            && m/^<<\s*\"/gc
            && do { $state = $quo = QUO7; $heredoc = ''; redo };
        $state == QUO7 && m/^([^"\\\n]+)/gc && do { $heredoc .= $1; redo };
        $state == QUO7 && m/^((?:\\.)+)/gc  && do { $heredoc .= $1; redo };
        $state == QUO7
            && m/^\"/gc
            && do { $state = HERE; $heredoc =~ s/\\\"/\"/g; redo };

        $state == PAR
            && m/^<<(\w*)/gc
            && do { $state = HERE; $quo = QUO7; $heredoc = $1; redo };

        # jump ahead and get the heredoc, then s/// also
        # resets the pos and we are back at the current pos
        $state == HERE
            && m/^.*\r?\n/gc
            && s/\G(.*?\r?\n)$heredoc(\r?\n)//s
            && do { $state = PAR; $str_part .= $1; $line_offset++; redo };

        # end ()
        #

        $state == PAR && m/^\s*[\)]/gc && do {
            $state = NUL;
            $vars =~ s/[\n\r]//g if ($vars);

            if ($str) {
                $result->add_entry_position( $str, $filename, $line - $line_offset ) # <= [MODIFIED] remove mystery line modifier
            }
            undef $str;
            undef $vars;
            undef $heredoc;
            $line_offset = 0;
            redo;
        };

        # a line of vars
        $state == PAR && m/^([^\)]*)/gc && do { $vars .= "$1\n"; redo };
    }

    return $result;
}

1;
__END__

=for stopwords foobar

=encoding utf-8

=head1 NAME

Localizer::Scanner::Perl - Scanner for file which is written by perl

=head1 SYNOPSIS

    use Localizer::Dictionary;
    use Localizer::Scanner::Perl;

    my $result  = Localizer::Dictionary->new();
    my $scanner = Localizer::Scanner::Perl->new();
    $scanner->scan_file($result, 'path/to/perl.pl');

=head1 METHODS

=over 4

=item * Localizer::Scanner::Perl()

Constructor. It makes scanner instance.

=item * $scanner->scan_file($result, $filename)

Scan file which is written by perl.
C<$result> is the instance of L<Localizer::Dictionary> to store results.
C<$filename> is file name of the target to scan.

For example, if target file is follows;

    print q{_("123")};
    print q{l("foo")};
    print q{loc("bar")};

Scanner uses C<_('foobar')>, C<l('foobar')> and C<loc('foobar')> as C<msgid> (in this case, 'foobar' will be C<msgid>).

C<$result> will be like a following;

    {
        '123' => {
            'position' => [ [ 'path/to/perl.pl', 1 ] ]
        },
        'foo' => {
            'position' => [ [ 'path/to/perl.pl', 2 ] ]
        },
        'bar' => {
            'position' => [ [ 'path/to/perl.pl', 3 ] ]
        }
    }

=item * $scanner->scan($result, $filename, $data)

This method is almost the same as C<scan_file()>.
This method does not load file contents, it uses C<$data> as file contents instead.

=back

=head1 SEE ALSO

L<Locale::Maketext::Extract::Plugin::Perl>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

