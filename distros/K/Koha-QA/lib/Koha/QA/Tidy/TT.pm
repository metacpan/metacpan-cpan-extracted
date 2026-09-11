package Koha::QA::Tidy::TT;

use Modern::Perl;
use base 'Koha::QA::Base';
use File::ShareDir qw(dist_file dist_dir);
use File::Slurp    qw(read_file write_file);
use File::Spec;
use IPC::Run3;

=head1 NAME

Koha::QA::Tidy::TT - Centralized Template Toolkit tidiness checking using prettier

=head1 SYNOPSIS

  use Koha::QA::Tidy::TT;

  # With a file
  my $checker = Koha::QA::Tidy::TT->new({file => $file, prettierrc => $prettierrc});

  # Or with content directly
  my $checker = Koha::QA::Tidy::TT->new({content => $file_content, prettierrc => $prettierrc});

  my $is_tidy = $checker->check;
  my @errors = $checker->errors;

  # Return the tidy version
  my $success = $checker->fix;

=head1 DESCRIPTION

This module provides centralized Template Toolkit tidiness checking
and formatting using prettier with the @koha-community/prettier-plugin-template-toolkit.

=head1 METHODS

=head2 new

  my $checker = Koha::QA::Tidy::TT->new({file => $file, prettierrc => $prettierrc});

Creates a new Tidy::TT instance.

Arguments:
  - prettierrc: Optional path to .prettierrc.js file (default: .prettierrc.js)

=head2 check

  my $is_tidy = $checker->check;

Checks if a Template Toolkit file is tidy by comparing the original content with
the output from prettier.

=head2 errors

  my @errors = $checker->errors;

Returns array of error hashrefs, each with:
  - error: the error type (tidy_tt, no_prettierrc, tidy_tt_empty_output, tidy_tt_prettier_failed)

=head2 fix

  my $output = $checker->fix;

Runs prettier on the file and returns the tidied content without modifying the file.

Returns:
  - String with tidied content on success
  - undef on failure

=cut

sub _prettier_cmd {
    my ( $self, $extra_args ) = @_;
    my $koha_qa_root      = dist_dir('Koha-QA');
    my $prettier          = File::Spec->catfile( $koha_qa_root, 'node_modules', 'prettier', 'bin', 'prettier.cjs' );
    my $relative_prettier = File::Spec->catfile( 'node_modules', 'prettier', 'bin', 'prettier.cjs' );
    my $args              = join( ' ', @$extra_args );

    # Change to koha_qa_root so Node.js can resolve the plugin by name from node_modules
    return [ 'sh', '-c', "cd '$koha_qa_root' && node $relative_prettier $args" ];
}

sub check {
    my ($self)     = @_;
    my $file       = $self->file;
    my $prettierrc = $self->{prettierrc} // dist_file( 'Koha-QA', 'prettierrc.js' );

    # _prettier_cmd() cd's into the share dir so Node can resolve the plugin from node_modules,
    # so a relative prettierrc must be resolved against the real cwd before that happens
    $prettierrc = File::Spec->rel2abs($prettierrc);

    # Check if prettier is available
    # FIXME Do we really need this additional prettier call per file?
    unless ( $self->_has_prettier() ) {
        $self->{_errors} = [ { error => 'prettier_not_installed', message => "prettier is not available" } ];
        return 0;
    }

    unless ( -f $prettierrc ) {
        $self->{_errors} = [
            {
                error   => 'no_prettierrc',
                message => "prettierrc file not found: $prettierrc",
            }
        ];
        return 0;
    }

    # For TT files, we need to handle the special substitutions that prettier does
    # Use a temp file to avoid modifying the original during the first pass
    my $file_fh   = File::Temp->new( CLEANUP => 1, SUFFIX => '.tt' );
    my $temp_file = $file_fh->filename;
    write_file( $temp_file, read_file($file) );

    my $tidy_output = q{};
    for my $pass ( 1 .. 2 ) {
        my $cmd = $self->_prettier_cmd( [ "--config=$prettierrc", "--write", $temp_file ] );
        my ( $stdout, $stderr );
        run3( $cmd, undef, \$stdout, \$stderr );

        # run3 always returns true regardless of the child's exit status;
        # the exit status must be checked via $? instead.
        my $success = $? == 0;

        # FIXME raise exception if stderr is defined?
        warn $stderr if $stderr;

        if ($success) {

            # Revert the substitutions done by the prettier plugin
            my $content = read_file($temp_file);
            $content =~ s#<!--</head>-->#</head>#g;
            $content =~ s#<!--<body(.*)-->#<body$1#g;
            $content =~ s#<!--</body>-->#</body>#g;
            $content =~ s#\n*( *)(<script\b[^>]*>)\n*#\n$1$2\n#g;
            $content =~ s#\n*( *)</script>\n*#\n$1</script>\n#g;
            $content =~ s#(\[%\s*SWITCH[^\]]*\]\n)\n#$1#g;

            if ( !length($content) && length( $self->content ) ) {
                $self->{_errors} = [
                    {
                        error   => 'tidy_tt_empty_output',
                        message => 'Prettier generated an empty file, the original content was kept',
                    }
                ];
                return 0;
            }
            if ( $pass == 1 ) {
                write_file( $temp_file, $content );
            } else {
                $tidy_output = $content;
            }
        } else {

            # prettier failed to process the file
            $self->{_errors} = [
                {
                    error   => 'tidy_tt_prettier_failed',
                    message => 'prettier failed to process the file, the original content was kept',
                }
            ];
            return 0;
        }
    }

    my $original = $self->content;

    $self->{_fixed_content} = $tidy_output;

    if ( $original eq $tidy_output ) {
        $self->{_errors} = [];
        return 1;
    } else {
        $self->{_errors} = [ { error => 'tidy_tt', message => "Template::Toolkit file is not tidy" } ];
        return 0;
    }
}

sub fix {
    my ($self) = @_;

    # If we haven't checked yet, check first
    $self->check unless exists $self->{_fixed_content};
    return $self->{_fixed_content};
}

sub _has_prettier {
    my ($self) = @_;
    my $cmd = $self->_prettier_cmd( ['--version'] );
    my ( $stdout, $stderr );
    eval { run3( $cmd, undef, \$stdout, \$stderr ) };
    return 0 if $@;
    return $? == 0;
}

1;

=head1 AUTHORS

Jonathan Druart <jonathan.druart@bugs.koha-community.org>

=head1 COPYRIGHT

Copyright 2026 Koha Development Team

=head1 LICENSE

This file is part of Koha.

Koha is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or (at your option) any later version.

=cut
