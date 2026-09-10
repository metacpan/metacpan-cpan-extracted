package Koha::QA::Spelling;

use Modern::Perl;
use base 'Koha::QA::Base';

=head1 NAME

Koha::QA::Spelling - Centralized spell checking using codespell

=head1 SYNOPSIS

  use Koha::QA::Spelling;

  # With a file
  my $checker = Koha::QA::Spelling->new({file => $file_path, ignore_file => $ignore_file});

  # Or with content directly
  my $checker = Koha::QA::Spelling->new({content => $file_content, ignore_file => $ignore_file});

  my $is_valid = $checker->check;
  my @errors = $checker->errors;

=head1 DESCRIPTION

This module provides centralized spell checking using codespell.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Spelling->new({file => $file_path, ignore_file => $ignore_file});

Creates a new Spelling checker instance.
Accepts either a 'file' parameter (path to a file) or a 'content' parameter (string content).

=head2 check

  my $is_valid = $checker->check;

Checks a file for spelling errors using codespell.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - file: The file path
  - message: The spelling error message

=cut

use IPC::Run3;

sub check {
    my ($self)      = @_;
    my $file        = $self->file;
    my $ignore_file = $self->{ignore_file};

    # Check if codespell is available
    unless ( $self->_has_codespell() ) {
        $self->{_errors} = [ { file => $file, message => 'codespell is not available' } ];
        return 0;
    }

    # Check if ignore file exists
    if ( defined $ignore_file && !-f $ignore_file ) {
        $self->{_errors} = [ { file => $file, message => "codespell ignore file not found: $ignore_file" } ];
        return 0;
    }

    my @cmd = ( 'codespell', '-d' );
    push @cmd, '--ignore-words', $ignore_file if $ignore_file;
    push @cmd, $file;
    my ( $stdout, $stderr );
    run3( \@cmd, undef, \$stdout, \$stderr );

    unless ($stdout) {
        $self->{_errors} = [];
        return 1;
    }

    my @exceptions = (
        qr{isnt\(},
    );

    # Encapsulate the potential errors
    my @errors;
    my @codespell_output = split /\n/, $stdout;
    for my $output_line (@codespell_output) {
        chomp $output_line;

        # Remove filepath and line numbers
        # my/file/path:xxx: identifier  ==> identifier
        my $re = q|^| . $file . q|:(\d+):|;
        if ( $output_line =~ $re ) {
            my $line_number = $1;
            my $p           = $file;
            my $guilty_line = `sed -n '${line_number}p' $p`;
            chomp $guilty_line;
            my $is_an_exception;
            for my $e (@exceptions) {
                if ( $guilty_line =~ $e ) {
                    $is_an_exception = 1;
                    last;
                }
            }
            unless ($is_an_exception) {
                push @errors, {
                    line        => $guilty_line,
                    line_number => $line_number,
                    error       => 'spelling',
                    message     => "Spelling error:" . $output_line =~ s|$re||r
                };
            }
        }
    }

    $self->{_errors} = \@errors;
    return @errors ? 0 : 1;
}

# Check if codespell is available
sub _has_codespell {
    my ($self) = @_;
    my ( $stdout, $stderr );
    eval { run3( [ 'codespell', '--version' ], undef, \$stdout, \$stderr ) };
    return 0 if $@;
    return $? == 0;
}

1;
