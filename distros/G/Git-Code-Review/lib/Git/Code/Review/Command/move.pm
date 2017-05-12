# ABSTRACT: Move a commit from one profile to another. Also available as mv.
package Git::Code::Review::Command::move;
use strict;
use warnings;

use CLI::Helpers qw(
    output
);
use Git::Code::Review -command;
use Git::Code::Review::Helpers qw(
    prompt_message
);
use Git::Code::Review::Utilities qw(:all);
use YAML;


sub command_names {
    return qw(move mv);
}

sub opt_spec {
    return (
        ['message|m|reason|r=s@',    "Reason for moving the commit to a different profile. If multiple -m options are given, their values are concatenated as separate paragraphs."],
        ['to=s',       "Profile to move the commit to." ],
    );
}

sub description {
    my $DESC = <<"    EOH";
    SYNOPSIS

        git-code-review move --to profile [options] <commit hash>

    DESCRIPTION

        Move a commit to another profile.

        Aliased as: move, mv

    EXAMPLES

        git-code-review move --to team_features 44d3b68e

        git-code-review move --to team_features -m "Not awesome enough for team awesome" 44d3b68e

    OPTIONS
    EOH
    $DESC =~ s/^[ ]{4}//mg;
    return $DESC;
}


sub execute {
    my($cmd,$opt,$args) = @_;
    die "Not initialized, run git-code-review init!" unless gcr_is_initialized();
    die "Need a profile to move to. Please specify with the --to option" unless $opt->{to};
    my $match = shift @$args;
    die "Too many arguments: " . join( ' ', @$args ) if scalar @$args > 0;
    if( !defined $match ) {
        output({color=>'red'}, "Please specify a commit hash from the source repository to approve.");
        exit 1;
    }

    # We need a reason for this move
    my $message = prompt_message( "Please provide the reason for the move (10+ chars or empty to abort):", $opt->{ message } );

    if ( $message =~ m/\S/s ) {
        # Validate Commit
        gcr_reset();
        my $commit = gcr_commit_info($match);
        gcr_change_profile($commit,$opt->{to},$message);
    } else {
        # allow user to abort with empty message
        output({color=>"red"}, "Empty message, skipped move.");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Git::Code::Review::Command::move - Move a commit from one profile to another. Also available as mv.

=head1 VERSION

version 2.6

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
