package Dist::Zilla::Plugin::ChangelogFromGit::Debian::Sequential;
{
  $Dist::Zilla::Plugin::ChangelogFromGit::Debian::Sequential::VERSION = '0.6';
}

# ABSTRACT: Add changelog entries into debain/changelog

use Moose;
extends 'Dist::Zilla::Plugin::ChangelogFromGit';
with 'Dist::Zilla::Role::AfterRelease';

use Debian::Control;
use Dpkg::Changelog::Parse;

use Dist::Zilla::File::InMemory;

use DateTime::Format::Mail;
use Text::Wrap qw(wrap fill);
use version;

override file_name => sub {'debian/changelog'};

sub render_changelog {
    my ($self) = @_;

    my ($pkg_name, $pkg_distr, $prev_version, $content);

    my $changelog_file = $self->_get_file('debian/changelog');
    if ($changelog_file) {
        my $changelog = changelog_parse(file => $changelog_file->_original_name);
        ($pkg_name, $pkg_distr, $prev_version) = map {$changelog->{$_}} qw(Source Distribution Version);
        $content = $changelog_file->content;
    } else {
        my $control = Debian::Control->new();

        my $control_file = $self->_get_file('debian/control');
        $self->logger->log_fatal("File 'debian/control' does not exist") unless $control_file;

        $control->read($control_file->_original_name);

        $pkg_name  = $control->source->Source;
        $pkg_distr = `lsb_release -cs`;
        chomp($pkg_distr);

        $prev_version = '0';

        $content = '';
    }

    $prev_version = version->parse($prev_version);

    local $Text::Wrap::huge    = 'wrap';
    local $Text::Wrap::columns = $self->wrap_column();

    $self->logger->log_fatal('Unsetted envirement variable DEBFULLNAME') unless $ENV{'DEBFULLNAME'};
    $self->logger->log_fatal('Unsetted envirement variable DEBEMAIL')    unless $ENV{'DEBEMAIL'};

    foreach my $release ($self->all_releases) {
        next if $release->has_no_changes && $release->version ne 'HEAD';
        next if $release->version ne 'HEAD' && $release->version <= version->parse($prev_version);

        my @changes;
        foreach my $change (@{$release->changes}) {
            # Ignoring merges
            my $log = Git::Repository::Log::Iterator->new($change->change_id);
            my $parents = $log->next->parent;
            $log->{'cmd'}->close();
            next if $parents > 1;

            my $text = $change->description;
            chomp($text);
            push(@changes, fill('  * ', '    ', $text));
        }

        my $version = $release->version;
        $version = $self->zilla->version if $version eq 'HEAD';

        $content =
            "$pkg_name ($version) $pkg_distr; urgency=low\n\n"
          . join("\n\n", @changes ? @changes : '  * No changes') . "\n\n"
          . " -- $ENV{'DEBFULLNAME'} <$ENV{'DEBEMAIL'}>  "
          . DateTime::Format::Mail->format_datetime($release->date->clone->set_time_zone('local'))
          . "\n\n$content";
    }

    return $content;
}

sub after_release {
    my ($self) = @_;

    my $fn = $self->zilla->root . "/debian/changelog";
    open(my $fh, '>', $fn) || $self->logger->log_fatal("Cannot write into '$fn': $!");
    print $fh $self->_get_file('debian/changelog')->content;
    close($fh);
}

sub add_file {
    my ($self, $file) = @_;

    if (my $added_file = $self->_get_file($file->name)) {
        $added_file->content($file->content);
    } else {
        return $self->SUPER::add_file($file);
    }

    return;
}

sub _get_file {
    my ($self, $name) = @_;

    return [grep {$_->name eq $name} @{$self->zilla->files}]->[0];
}

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::ChangelogFromGit::Debian::Sequential - Sequential Debian formatter for Changelogs

=head1 SYNOPSIS

    [ChangelogFromGit::Debian::Sequential]
    [@Git]

=head1 DESCRIPTION

ChangelogFromGit::Debian::Sequential extends L<Dist::Zilla::Plugin::ChangelogFromGit> to create/update Debian changelog.
It does not recreate changelog every time like L<Dist::Zilla::Plugin::ChangelogFromGit::Debian>.

=head1 AUTHOR

Sergei Svistunov <svistunov@yandex.ru>

=cut
