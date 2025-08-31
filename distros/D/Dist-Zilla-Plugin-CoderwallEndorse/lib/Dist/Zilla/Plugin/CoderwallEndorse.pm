package Dist::Zilla::Plugin::CoderwallEndorse;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Adds a Coderwall 'endorse' button to README Markdown file (DEPRECATED)
$Dist::Zilla::Plugin::CoderwallEndorse::VERSION = '0.2.1';

use strict;
use warnings;

use Moose;

use List::Util qw/ first /;

use Dist::Zilla::Role::File::ChangeNotification;

with qw/
    Dist::Zilla::Role::Plugin
    Dist::Zilla::Role::FileMunger
/;

has users => (
    is => 'ro',
    isa => 'Str',
);

has "filename" => (
    isa => 'Str',
    is => 'ro',
    default => 'README.mkdn',
);

has mapping => (
    traits => [ 'Hash' ],
    is => 'ro',
    isa => 'HashRef',
    lazy => 1,
    default => sub {
        my $self = shift;
        my %m;
        for my $p ( split /\s*,\s*/, $self->users ) {
            my( $cd, $auth) = $p =~ /(\w+)\s*:\s*(.+?)\s*$/;
            $m{$auth} = $cd;
        }

        return \%m;
    },
    handles => {
        'authors' => 'keys',
        'cd_user' => 'get',
    },
);

has "_last_content" => (
    isa => 'Str',
    is => 'rw',
    default => '',
);

sub munge_files {
    my $self = shift;

    my $filename = $self->filename;
    my( $file ) = grep { $_->name eq $filename } @{ $self->zilla->files }
        or return $self->log([ "file '%s' not found", $filename ]);

    $self->munge_file($file);
    $self->watch($file);
}

sub watch {
    my( $self, $file ) = @_;
    
    Dist::Zilla::Role::File::ChangeNotification->meta->apply($file)
        unless $file->does('Dist::Zilla::Role::File::ChangeNotification');

    my $plugin = $self;
    $file->on_changed(sub {
        my ($self, $newcontent) = @_;

        $self->_content_checksum(0);
        $self->watch_file;

        # If the new content is actually different, recalculate
        # the content based on the updates.
        return if $newcontent eq $plugin->_last_content;

        $plugin->log_debug('someone tried to munge ' . $self->name . ' after we read from it. Making modifications again...');
        $plugin->munge_file($file);
    });

    $file->watch_file;
}

sub munge_file {
    my( $self, $file ) = @_;

    $self->log_debug([ 'CoderwallEndorse updating contents of %s in dist', $file->name ]);

    my $new_content;

    for my $line ( split /\n/, $file->content ) {
        if ( $line=~ /^# AUTHOR/ ... $line =~ /^#/ ) {
            for my $auth ( $self->authors ) {

                # author not mentioned, or endorse link already there
                next if -1 == index $line, $auth
                     or -1 != index $line, '[endorse]';

                $line .= sprintf " [![endorse](http://api.coderwall.com/%s/endorsecount.png)](http://coderwall.com/%s)",
                                ( $self->cd_user($auth) ) x 2;

            }
        }
        $new_content .= $line."\n";
    }

    $self->_last_content($new_content);
    $file->content($new_content);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CoderwallEndorse - Adds a Coderwall 'endorse' button to README Markdown file (DEPRECATED)

=head1 VERSION

version 0.2.1

=head1 SYNOPSIS

    ; in dist.ini

    ; typically, to create the README off the main module
    [ReadmeMarkdownFromPod]

    [CoderwallEndorse]
    filename = README.mkdn
    users = coderwall_name : author name, other_cw_name : other author

=head1 DESCRIPTION

B<Deprecated>: Coderwall endorse buttons are, alas, not a thing anymore. :-(

If a C<README.mkdn> file is presents, a Coderwall 'endorse' button will be
added beside author names if a author-name-to-coderwall-user mapping has been
given.

=head1 SEE ALSO

L<http://www.coderwall.com>

L<Dist::Zilla::Plugin::ReadmeMarkdownFromPod>

For an example of what the result of this plugin looks like, see its
GitHub main page: L<https://github.com/yanick/Dist-Zilla-Plugin-CoderwallEndorse>

Original blog entry: L<http://babyl.dyndns.org/techblog/entry/coderwall-button>

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
