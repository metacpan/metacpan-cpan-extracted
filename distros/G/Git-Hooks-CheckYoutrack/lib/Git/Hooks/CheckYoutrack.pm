# ========================================================================== #
# lib/Git/Hooks/Youtrack.pm - Github Hooks for youtrack
# ========================================================================== #

package Git::Hooks::CheckYoutrack;

use strict;
use warnings;
use utf8;
use Log::Any '$log';
use Path::Tiny;
use Git::Hooks;
use LWP::UserAgent;
use URI::Builder;
use JSON::XS;

$Git::Hooks::CheckYoutrack::VERSION = '1.0.2';

=head1 NAME

Git::Hooks::CheckYoutrack - Git::Hooks plugin which requires youtrack ticket number on each commit message

=head1 SYNOPSIS

As a C<Git::Hooks> plugin you don't use this Perl module directly. Instead, you
may configure it in a Git configuration file like this:

 [githooks]
 
    # Enable the plugin
    plugin = CheckYoutrack

 [githooks "checkyoutrack"]

    # '/youtrack' will be appended to this host
    youtrack-host = "https://example.myjetbrains.com"

    # Refer: https://www.jetbrains.com/help/youtrack/standalone/Manage-Permanent-Token.html
    # to create a Bearer token
    # You can also set YoutrackToken ENV instead of this config
    youtrack-token = "<your-token>"

    # Regular expression to match for Youtrack ticket id
    matchkey = "^((?:P)(?:AY|\\d+)-\\d+)"

    # Setting this flag will aborts the commit if valid Youtrack number not found
    # Shows a warning message otherwise - default false
    required = true 

    # Print the fetched youtrack ticket details like Assignee, State etc..,
    # default false
    print-info = true


=head1 DESCRIPTION

This plugin hooks the following git hooks to guarantee that every commit message 
cites a valid Youtrack Id in the log message, so that you can be certain that 
every commit message has a valid link to the Youtrack ticket. Refer L<Git::Hooks Usage|https://metacpan.org/pod/Git::Hooks#USAGE> 
for steps to install and use Git::Hooks

This plugin also hooks prepare-commit-msg to pre-populate youtrack ticket sumary on the 
commit message if the current working branch name is starting with the valid ticket number

=head1 METHODS

=cut

my $PKG = __PACKAGE__;
(my $CFG = __PACKAGE__) =~ s/.*::/githooks./;

# =========================================================================== #

=head2 B<commit-msg>, B<applypatch-msg>
 
These hooks are invoked during the commit, to check if the commit message
starts with a valid Youtrack ticket Id.

=cut

sub check_commit_msg {
    my ($git, $message, $commit_id) = @_;

    # Skip for empty message
    return 'no_check' if (!$message || $message =~ /^[\n\r]$/g);

    $log->info("Checking commit message: $message");

    my $yt_id = _get_youtrack_id($git, $message);

    if (!$yt_id) {
        return _show_error($git, "Missing youtrack ticket id in your message: $message");
    }

    $log->info("Extracted Youtrack ticket id from message as: $yt_id");

    my $yt_ticket = _get_ticket($git, $yt_id);

    if (!$yt_ticket) {
        return _show_error($git, "Youtrack ticket not found with ID: $yt_id");
    }

    if ($yt_ticket && $git->get_config_boolean($CFG => 'print-info')) {
        print '-' x 80 . "\n";
        print "For git commit:  $commit_id\n" if($commit_id);
        print "Youtrack ticket: $yt_ticket->{ticket_id}\n";
        print "Summary:         $yt_ticket->{summary}\n";
        print "Current status:  $yt_ticket->{State}\n";
        print "Assigned to:     $yt_ticket->{Assignee}\n";
        print "Ticket Link:     $yt_ticket->{WebLink}\n";
        print '-' x 80 . "\n";
    }

    return 0;
}

# =========================================================================== #

sub check_message_file {
    my ($git, $commit_msg_file) = @_;

    $log->debug(__PACKAGE__ . "::check_message_file($commit_msg_file)");

    _setup_config($git);

    my $msg = _get_message_from_file($git, $commit_msg_file);

    # Remove comment lines from the message file contents.
    $msg =~ s/^#[^\n]*\n//mgs;

    return check_commit_msg($git, $msg);
}

# =========================================================================== #

sub _show_error {
    my ($git, $msg) = @_;
    $log->error($msg);
    if ($git->get_config_boolean($CFG => 'required')) {
        $git->fault("ERROR: $msg");
        return 1;
    }
    else {
        print "WARNING: $msg\n";
        return 0;
    }
}

# =========================================================================== #

=head2 B<update>

This hook is for remote repository and should be installed and configured at the remote git server.
Checks for youtrack ticket on each commit message pushed to the remote repository and deny push
if its not found and its required = true in the config, shows a warning message on client side 
if config required = false but accepts the push.

=cut

sub check_affected_refs {
    my ($git) = @_;

    $log->debug(__PACKAGE__ . "::check_affected_refs");

    _setup_config($git);

    my $errors = 0;

    foreach my $ref ($git->get_affected_refs()) {
        next unless $git->is_reference_enabled($ref);
        if(check_ref($git, $ref)) {
            ++$errors;
        }
    }

    if($errors) {
        return _show_error($git, "Some of your commit message missing a valid youtrack ticket");
    }

    return 0;
}

# =========================================================================== #

sub check_ref {
    my ($git, $ref) = @_;

    my $errors = 0;

    foreach my $commit ($git->get_affected_ref_commits($ref)) {
        local $log->context->{commit_id} = $commit->commit;
        $log->info("Commit from : ", $commit->author_name, " Git Ref: ", $ref);
        if(check_commit_msg($git, $commit->message, $commit->commit)) {
            ++$errors;
        }
    }

    return $errors;
}

# =========================================================================== #

=head2 B<prepare-commit-msg>
 
This hook is invoked before a commit, to check if the current branch name start with 
a valid youtrack ticket id and pre-populates the commit message with youtrack ticket: summary

=cut

sub add_youtrack_summary {
    my ($git, $commit_msg_file) = @_;

    $log->debug(__PACKAGE__ . "::add_youtrack_summary($commit_msg_file)");

    _setup_config($git);

    my $msg      = _get_message_from_file($git, $commit_msg_file);
    my $msg_copy = $msg;

    # Remove comment lines and empty lines from the message file contents.
    $msg =~ s/^#[^\n]*\n//mgs;
    $msg =~ s/^\n*\n$//msg;

    # Don't do anything if message already exist (user used -m option)
    if ($msg) {
        $log->info("Message exist: $msg");
        return 0;
    }

    my $current_branch = $git->get_current_branch();

    # Extract current branch name
    $current_branch =~ s/.+\/(.+)/$1/;

    my $yt_id = _get_youtrack_id($git, $current_branch);

    if (!$yt_id) {
        $log->warn("No youtrack id in your working branch");
        return 0;
    }

    my $task = _get_ticket($git, $yt_id);

    if (!$task) {
        $log->warn("Your branch name does not match with youtrack ticket");
        return 0;
    }

    my $ticket_msg = "$yt_id: $task->{summary}\n";

    $log->info("Pre-populating commit message as: $ticket_msg");

    open my $out, '>', path($commit_msg_file) or die "Can't write new file: $!";
    print $out $ticket_msg;
    print $out $msg_copy;
    close $out;
}

# =========================================================================== #

sub _get_message_from_file {
    my ($git, $file) = @_;

    my $msg = eval { path($file)->slurp };
    defined $msg
      or $git->fault("Cannot open file '$file' for reading:", {details => $@})
      and return 0;

    return $msg;
}

# =========================================================================== #

# Setup default configs
sub _setup_config {
    my ($git) = @_;

    my $config = $git->get_config();

    $config->{lc $CFG} //= {};

    my $default = $config->{lc $CFG};

    # Default matchkey for matching Youtrack ids (P3-1234 || PAY-1234) keys.
    $default->{matchkey} //= ['^(P(?:AY|\d+)-\d+)'];

    $default->{required} //= ['false'];

    $default->{'print-info'} //= ['false'];

    return;
}

# =========================================================================== #

# Tries to get a valid youtrack ticket and return a HashRef with ticket details if found success
sub _get_ticket {
    my ($git, $ticket_id) = @_;

    my $yt_token = $git->get_config($CFG => 'youtrack-token');

    $yt_token = $ENV{YoutrackToken} if (!$yt_token);

    if (!$yt_token) {
        my $error = "Please set Youtrack permanent token in ENV YoutrackToken\n";
        $error .= "Refer: https://www.jetbrains.com/help/youtrack/standalone/Manage-Permanent-Token.html\n";
        $error .= "to generate a token\n";
        $git->fault($error);
        return;
    }

    my $yt_host = $git->get_config($CFG => 'youtrack-host');
    my $yt      = URI::Builder->new(uri => $yt_host);

    my $ua = $git->{yt_ua} //= LWP::UserAgent->new();
    $ua->default_header('Authorization' => "Bearer $yt_token");
    $ua->default_header('Accept'        => 'application/json');
    $ua->default_header('Content-Type'  => 'application/json');

    my $ticket_fields = 'fields=numberInProject,project(shortName),summary,customFields(name,value(name))';

    $yt->path_segments("youtrack", "api", "issues", $ticket_id);

    my $url = $yt->as_string . "?$ticket_fields";

    my $ticket = $ua->get($url);

    if (!$ticket->is_success) {
        $log->error("Youtrack fetch failed with status: ", $ticket->status_line);
        return;
    }

    my $json           = decode_json($ticket->decoded_content);
    my $ticket_details = _process_ticket($json);

    if (!$ticket_details->{ticket_id}) {
        $log->error("No valid youtrack ticket found");
        return;
    }

    $ticket_details->{Assignee} = 'Unassigned' if (!$ticket_details->{Assignee});

    $yt->path_segments('youtrack', 'issue', $ticket_id);
    $ticket_details->{WebLink} = $yt->as_string;

    return $ticket_details;
}

# =========================================================================== #

# Helper method to process the response from Youtrack API
sub _process_ticket {
    my $json = shift;

    return if (!$json);
    my $ticket;

    $ticket->{summary}   = $json->{summary};
    $ticket->{type}      = $json->{'$' . 'type'};
    $ticket->{ticket_id} = $json->{numberInProject};

    if ($json->{project} && $json->{project}->{shortName}) {
        $ticket->{ticket_id} = $json->{project}->{shortName} . '-' . $ticket->{ticket_id};
    }

    if ($json->{customFields}) {
        foreach my $field (@{$json->{customFields}}) {

            if (ref $field->{value} eq 'HASH') {
                $ticket->{$field->{name}} = $field->{value}->{name};
            }
            elsif (ref $field->{value} eq 'ARRAY') {
                foreach my $val (@{$field->{value}}) {
                    $ticket->{$field->{name}} = join(',', $val->{name});
                }
            }
            else {
                $ticket->{$field->{name}} = $field->{value};
            }
        }
    }

    return $ticket;
}

# =========================================================================== #

# Check and return a youtrack Id in the given string based on the matchkey regex
sub _get_youtrack_id {
    my ($git, $message) = @_;

    my $matchkey = $git->get_config($CFG => 'matchkey');

    chomp $message;

    if ($message =~ /$matchkey/i) {
        return uc($1);
    }

    $log->info("\"$message\" does not match /$matchkey/");

    return;
}

# =========================================================================== #

=head1 USAGE INSTRUCTION

Create a generic script that will be invoked by Git for every hook. Go to hooks directory of your repository,
for local repository it is .git/hooks/ and for remote server it is ./hooks/ and create a simple executable perl script

    $ cd /path/to/repo/.git/hooks
 
    $ cat >git-hooks.pl <<'EOT'
    #!/usr/bin/env perl
    use Git::Hooks;
    run_hook($0, @ARGV);
    EOT
 
    $ chmod +x git-hooks.pl

Now you should create symbolic links pointing to this perl script for each hook you are interested in

For local repository

    $ cd /path/to/repo/.git/hooks

    $ ln -s git-hooks.pl commit-msg
    $ ln -s git-hooks.pl applypatch-msg
    $ ln -s git-hooks.pl prepare-commit-msg

For remote repository

    $ cd /path/to/repo/hooks

    $ ln -s git-hooks.pl update

=cut

# Install hooks via Git::Hooks
APPLYPATCH_MSG \&check_message_file;
COMMIT_MSG \&check_message_file;
PREPARE_COMMIT_MSG \&add_youtrack_summary;
UPDATE \&check_affected_refs;

# =========================================================================== #

1;

__END__

=head1 SEE ALSO

Git::Hooks

=head1 AUTHORS

Dinesh Dharmalingam, <dd.dinesh.rajakumar@gmail.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

