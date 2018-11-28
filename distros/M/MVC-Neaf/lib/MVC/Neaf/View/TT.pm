package MVC::Neaf::View::TT;

use 5.006;
use strict;
use warnings;

our $VERSION = 0.2603;

=head1 NAME

MVC::Neaf::View::TT - Template toolkit-based view module for Neaf.

=head1 SYNOPSYS

    # Somewhere in your app
    return {
        -view => 'TT',
        -template => 'foo.tt',
        title => 'Page title',
        ....
    };
    # Neaf knows it's time to render foo.tt with returned data as stash
    # and return result to user

    # What actually happens
    my $view = MVC::Neaf::View::TT->new;
    my $content = $view->render( { ... } );

    # And if in foo.tt
    <title>[% title %]</title>

    # Then in $content it becomes
    <title>Page title</title>

=head1 DESCRIPTION

This module is one of core rendering engines of L<MVC::Neaf>
known under C<TT> alias.

See also C<neaf view>.

=head1 METHODS

=cut

use Carp;
use Template;
use Template::Provider;

our @CARP_NOT = qw(MVC::Neaf::View MVC::Neaf MVC::Neaf::Request);

use parent qw(MVC::Neaf::View);

=head2 new( %options )

%options may include:

=over

=item * template - default template to use.

=item * preserve_dash - don't strip dashed options. Useful for debugging.

=item * preload => { name => 'in-memory template' } - preload some templates.
See C<preload()> below.

Also any UPPERCASE OPTIONS will be forwarded to the backend
(i.e. Template object) w/o changes.

Any extra options except those above will cause an exception.

=back

=cut

my %new_opt;
$new_opt{$_}++ for qw( template preserve_dash engine preload preload_auto );

my @opt_provider = qw(
    INCLUDE_PATH ABSOLUTE RELATIVE DEFAULT ENCODING CACHE_SIZE STAT_TTL
    COMPILE_EXT COMPILE_DIR TOLERANT PARSER DEBUG EVAL_PERL
);

sub new {
    my ($class, %opt) = @_;

    my %tt_opt;
    $tt_opt{$_} = delete $opt{$_}
        for grep { /^[A-Z]/ } keys %opt;
    my @extra = grep { !$new_opt{$_} } keys %opt;
    croak( "$class->new: Unknown options @extra" )
        if @extra;

    $opt{engine} ||= do {
        my %prov_opt;
        $tt_opt{INCLUDE_PATH} ||= [];
        $prov_opt{$_} = $tt_opt{$_}
            for @opt_provider;
        defined $prov_opt{$_} or delete $prov_opt{$_}
            for keys %prov_opt;

        my $prov = delete $tt_opt{LOAD_TEMPLATES} || [
            Template::Provider->new(\%prov_opt)
        ];
        $opt{engine_preload} = Template::Provider->new({
            %prov_opt,
            CACHE_SIZE => undef,
            STAT_TTL   => 4_000_000_000,
        });
        # shallow copy (not unshift) to avoid spoiling original values
        $prov = [ $opt{engine_preload}, @$prov ];

        Template->new (%tt_opt, LOAD_TEMPLATES => $prov);
    };

    my $pre = delete $opt{preload};
    my $self = $class->SUPER::new(%opt);

    # TODO 0.40 automagically preload from the calling file's DATA section
    if ( ref $pre eq 'HASH' ) {
        $self->preload( $_ => $pre->{$_} )
            for keys %$pre;
    } elsif ($pre) {
        $self->_croak("preload must be a hash, not ".(ref $pre || "a scalar") );
    };
    return $self;
};

=head2 render( \%data )

Returns a pair of values: ($content, $content_type).

Content-type defaults to text/html.

The template is determined from (1) -template in data (2) template in new().
If neither is present, empty string and "text/plain" are returned.

=cut

sub render {
    my ($self, $data) = @_;

    my $template = $data->{-template} || $self->{template};

    if (!defined $template) {
        croak __PACKAGE__.": -template option is required";
    };

    my $out;
    $self->{engine}->process( $template, $data, \$out )
        or $self->_croak( $self->{engine}->error );

    return wantarray ? ($out, "text/html") : $out;
};

=head2 preload ( name => "[% in_memory_template %]", ... )

Store precompiled templates under given names.

Returns self, dies on error.

=cut

sub preload {
    my ($self, %tpls) = @_;

    foreach (keys %tpls) {
        my $compiled = eval { $self->{engine}->template( \$tpls{$_} ) }
            or $self->_croak( "$_: $@" );

        $self->{engine_preload}->store( $_, $compiled );
    };

    return $self;
};

sub _croak {
    my ($self, @msg) = @_;

    my $where = [caller(1)]->[3];
    $where =~ s/.*:://;

    croak join "", (ref $self || $self), '->', $where, "(): ", @msg;
};

=head1 SEE ALSO

L<Template> - the template toolkit used as backend.

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
