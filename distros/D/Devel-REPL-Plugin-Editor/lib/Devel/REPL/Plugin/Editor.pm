## no critic (RequireUseStrict)
package Devel::REPL::Plugin::Editor;
$Devel::REPL::Plugin::Editor::VERSION = '0.02';
## use critic (RequireUseStrict)
use Devel::REPL::Plugin;
use File::Slurp qw(read_file);
use File::Temp ();

use namespace::clean -except => 'meta';

has evaluating_file_contents => (
    is      => 'rw',
    default => 0,
);

has previously_edited_file => (
    is => 'rw',
);

sub command_edit {
    my ( $self, undef, $filename ) = @_;

    # If filename was not provided, make one up
    if(!defined($filename) || $filename eq '') {
        my $tempfile = File::Temp->new(SUFFIX => '.pl');
        close $tempfile;
        $filename = $tempfile->filename;
        $self->previously_edited_file($tempfile);
    } else {
        $self->previously_edited_file($filename);
    }
    $filename = "$filename"; # we could've gotten a File::Temp from
                             # command_redit

    system $ENV{'EDITOR'}, $filename;

    my $code = read_file($filename);
    chomp $code;
    my $pristine_code = $code;

    if($self->can('current_package')) {
        $code = "package " . $self->current_package . ";\n$code";
    }

    my $rl = $self->term;

    if($rl->ReadLine eq 'Term::ReadLine::Gnu') {
        my $location = $rl->where_history;
        $rl->replace_history_entry($location, $pristine_code);
    } else {
        $self->term->addhistory($pristine_code);
    }

    $self->evaluating_file_contents(1);
    my @result = $self->formatted_eval($code);
    $self->evaluating_file_contents(0);
    return @result;
}

sub command_redit {
    my ( $self ) = @_;

    my $filename = $self->previously_edited_file;

    if(defined $filename) {
        return $self->command_edit(undef, $filename);
    } else {
        die q{You haven't used #edit yet};
    }
}

sub BEFORE_PLUGIN {
    my ( $repl ) = @_;

    $repl->load_plugin('Turtles');
    $repl->add_turtles_matcher(sub {
        my ( $line ) = @_;

        my $prefix = $repl->default_command_prefix;

        if($repl->evaluating_file_contents && $line =~ /^${prefix}(?:r?)edit/) {
            return {}; # this will be processed by Turtles' formatted_eval,
                       # which should ignore it
        }

        return;
    });
}

1;

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Editor - Add #edit command to drop into an editor for longer expressions

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # in ~/.re.pl/repl.rc
  $_REPL->load_plugin('Editor');

=head1 DESCRIPTION

This plugin adds an C<edit> command to your REPL, invoked using C<#edit> (or
using whatever L<Devel::REPL::Plugin::Turtles/default_command_prefix> is).
When you run the the edit command, the REPL drops you into C<$ENV{'EDITOR'}>,
and the code you type in that file is executed after you exit the editor.
C<edit> accepts an optional filename as the file to edit.  If you don't
provide one, a temporary one will be created; you can open it again with
the C<#redit> command.

=head1 SEE ALSO

L<Devel::REPL>

=begin comment

=over

=item BEFORE_PLUGIN

=item command_edit

=item command_redit

=back

=end comment

=head1 AUTHOR

Rob Hoelz <rob@hoelz.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Rob Hoelz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/hoelzro/devel-repl-plugin-editor/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut

__END__

# ABSTRACT: Add #edit command to drop into an editor for longer expressions

