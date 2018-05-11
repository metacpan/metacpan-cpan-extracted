package Dist::Zilla::Plugin::LocalHTML::Pod2HTML;

# ABSTRACT: Pod::Simple::HTML wrapper to generate local links for project modules.

our $VERSION = 'v0.2.4';

use File::Spec;
use Data::Dumper;
use Cwd;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends qw<Pod::Simple::HTML>;


has callerPlugin => (
    is      => 'ro',
    isa     => 'Dist::Zilla::Plugin::LocalHTML',
    handles => [qw<log log_debug>],
);


has prefixRx => (
    is      => 'ro',
    lazy    => 1,
    builder => 'init_prefixRx',
);

has local_files => (
    is      => 'ro',
    lazy    => 1,
    clearer => 'clear_local_files',
    builder => 'init_local_files',
);


sub _mod2file {
    my $this = shift;
    my $mod  = shift;
    my $file = File::Spec->catfile( split /::/, $mod );
    return $this->callerPlugin->base_filename($file);
}

around do_pod_link => sub {
    my $orig   = shift;
    my $this   = shift;
    my ($link) = @_;

    if (   ( $link->tagname eq 'L' )
        && ( $link->attr('type') eq 'pod' ) )
    {
        my $ref = "";
        if ( $link->attr('to') ) {
            my $lpRx   = $this->prefixRx;
            my $to     = "" . $link->attr('to');
            my $toFile = $this->_mod2file($to);
            $this->log_debug("'$to' matches local prefix")
              if defined($lpRx) && $to =~ /^$lpRx/;
            $this->log_debug("'$toFile' is in local_files map")
              if $this->local_files->{$toFile};
            if ( ( defined($lpRx) && $to =~ /^$lpRx/ )
                || $this->local_files->{$toFile} )
            {
                # Local link
                $ref .= $toFile;
            }
            else {
                # External link. Override default generator because
                # search.cpan.org seems to be down as for now.
                $ref .= "https://metacpan.org/pod/$to";
            }
        }
        if ( $link->attr('section') ) {
            my $section = "" . $link->attr('section');
            $ref .= "#" . $this->section_escape($section);
        }
        if ($ref) {
            $this->log_debug( "Resulting link:", $ref );
            return $ref;
        }
    }

    return $orig->( $this, @_ );
};


sub init_prefixRx {
    my $this   = shift;
    my @pfList = @{ $this->callerPlugin->local_prefix };
    return @pfList
      ? "(?<prefix>" . join( "|", @pfList ) . ")"
      : undef;
}

sub init_local_files {
    my $this = shift;

    my $files = $this->callerPlugin->found_files;
    my $map   = {};

    foreach my $file (@$files) {
        $map->{ $this->callerPlugin->base_filename( $file->name ) } = 1
          if $this->callerPlugin->is_interesting_file($file);
    }
    return $map;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::LocalHTML::Pod2HTML - Pod::Simple::HTML wrapper to generate local links for project modules.

=head1 VERSION

version v0.2.4

=head1 ATTRIBUTES

=head2 C<callerPlugin>

Points back to the parent plugin object.

=head2 prefixRx

Contains regexp for matching local modules.

=head2 local_files

List of files to build docs for.

=head1 METHODS

=head2 C<do_pod_link>

Inherited from L<Pod::Simple::HTML>

=head2 C<init_prefixRx>

Builder for C<prefixRx> attribute. Generates regexp from caller plugin
C<local_prefix> attribute.

=head2 C<init_local_files>

Builder for C<local_files> attribute. Records local files to be processed.

=head1 AUTHOR

Vadim Belman <vrurg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Vadim Belman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
