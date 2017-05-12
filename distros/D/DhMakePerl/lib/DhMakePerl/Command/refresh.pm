package DhMakePerl::Command::refresh;

=head1 NAME

DhMakePerl::Command::refresh - dh-make-perl refresh implementation

=head1 DESCRIPTION

This module implements the I<refresh> command of L<dh-make-perl(1)>.

=cut

use strict; use warnings;

our $VERSION = '0.84';

use base 'DhMakePerl::Command::Packaging';
use Debian::Control::FromCPAN;
use Debian::WNPP::Query ();
use File::Spec::Functions qw(catfile);
use Tie::File;

=head1 METHODS

=over

=item execute

Provides I<refresh> command implementation.

=cut

sub execute {
    my $self = shift;

    $self->main_dir( $ARGV[0] || '.' );
    print "Engaging refresh mode in " . $self->main_dir . "\n"
        if $self->cfg->verbose;

    if ( not $self->cfg->_explicitly_set->{'source-format'}
        and -e ( my $f = catfile( $self->debian_file('source'), 'format' ) ) )
    {
        open( my $fh, '<', $f ) or die "open($f): $!";
        my $present = <$fh>;
        close $fh;

        chomp($present) if $present;
        if ($present) {
            $self->cfg->source_format($present);
            print "Detected source format: $present\n"
                if $self->cfg->verbose;
        }
    }

    $self->control->read( $self->debian_file('control') );
    $self->fill_maintainer;
    $self->process_meta;
    $self->extract_basic();    # also detects arch-dep package

    $self->extract_docs     if $self->cfg->only->{docs};
    $self->extract_examples if $self->cfg->only->{examples};
    print "Found docs: @{ $self->docs }\n"
        if @{ $self->docs } and $self->cfg->verbose;
    print "Found examples: @{ $self->examples }\n"
        if @{ $self->examples } and $self->cfg->verbose;

    if ( $self->cfg->only->{only} ) {
        $self->create_rules;
        $self->create_compat( $self->debian_file('compat') );
    }

    if ( $self->cfg->only->{examples} ) {
        $self->update_file_list( examples => $self->examples );
    }

    if ( $self->cfg->only->{docs} ) {
        $self->update_file_list( docs => $self->docs );
    }

    if ( $self->cfg->only->{copyright} ) {
        $self->backup_file( $self->debian_file('copyright') );
        $self->create_copyright( $self->debian_file('copyright') );
    }

    if ( $self->cfg->only->{control} ) {
        my $control = $self->control;
        if ( -e catfile( $self->debian_file('patches'), 'series' )
            and $self->cfg->source_format ne '3.0 (quilt)' )
        {
            $self->add_quilt($control);
        }
        else {
            $self->drop_quilt($control);
        }

        $self->write_source_format(
            catfile( $self->debian_dir, 'source', 'format' ) );

        $self->discover_dependencies;

        $self->discover_utility_deps($control);
        $control->prune_perl_deps();

        $self->backup_file( $self->debian_file('control') );
        $control->write( $self->debian_file('control') );
    }

    print "--- Done\n" if $self->cfg->verbose;
    return 0;
}

=item add_quilt( $control )

Plugs quilt into F<debian/rules> and F<debian/control>. Depends on
F<debian/rules> being in L<dh(1)> three-liner format. Also adds debian/README.source
documenting quilt usage.

=cut

sub add_quilt {
    my( $self, $control ) = @_;

    $self->read_rules;

    $self->rules->add_quilt;

    # README.source
    my $quilt_mini_doc = <<EOF;
This package uses quilt for managing all modifications to the upstream
source. Changes are stored in the source package as diffs in
debian/patches and applied during the build.

See /usr/share/doc/quilt/README.source for a detailed explaination.
EOF

    my $readme = $self->debian_file('README.source');
    my $quilt_already_documented = 0;
    my $readme_source_exists = -e $readme;
    if($readme_source_exists) {
        my @readme;
        tie @readme, 'Tie::File', $readme
            or die "Unable to tie '$readme': $!";

        for( @readme ) {
            if( m{quilt/README.source} ) {
                $quilt_already_documented = 1;
                last;
            }
        }
    }

    print "README.source already documents quilt\n"
        if $quilt_already_documented and $self->cfg->verbose;

    unless($quilt_already_documented) {
        my $fh;
        open( $fh, '>>', $readme )
            or die "Unable to open '$readme' for writing: $!";

        print $fh "\n\n" if $readme_source_exists;
        print $fh $quilt_mini_doc;
        close $fh;
    }
}

=item drop_quilt( $control )

removes quilt from F<debian/rules>. Expects that
L<|add_quilt> was used to add quilt to F<debian/rules>.

If F<debian/README.source> exists, references to quilt are removed from it (and
the file removed if empty after that).

Both L<dh(1)> style (C<dh --with=quilt>) and old-fashioned (C<$(QUILT_STAMPFN)>
target dependency) are supported.

=cut

sub drop_quilt {
    my( $self, $control ) = @_;

    $self->read_rules;

    $self->rules->drop_quilt;

    # README.source
    my $readme = $self->debian_file('README.source');

    if( -e $readme ) {
        my @readme;
        tie @readme, 'Tie::File', $readme
            or die "Unable to tie '$readme': $!";

        my( $start, $end );
        for( my $i = 0; defined( $_ = $readme[$i] ); $i++ ) {
            if( m{^This package uses quilt } ) {
                $start = $i;
                next;
            }

            if( defined($start)
                    and m{^See /usr/share/doc/quilt/README.source} ) {
                $end = $i;
                last;
            }
        }

        if( defined($start) and defined($end) ) {
            print "Removing references to quilt from README.source\n"
                if $self->cfg->verbose;

            splice @readme, $start, $end-$start+1;

            # file is now empty?
            if( join( '', @readme ) =~ /^\s*$/ ) {
                unlink $readme
                    or die "unlink($readme): $!";
            }
        }
    }
}

=back

=cut

1;

=head1 COPYRIGHT & LICENSE

=over

=item Copyright (C) 2008, 2009, 2010 Damyan Ivanov <dmn@debian.org>

=item Copyright (C) 2010, 2014 gregor herrmann <gregoa@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

