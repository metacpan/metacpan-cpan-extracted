package Games::Lacuna::Task::Report::Glyph;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use Games::Lacuna::Client::Types qw(ore_types);

sub report_glyph {
    my ($self) = @_;
    
    my $table = Games::Lacuna::Task::Table->new(
        headline=> 'Glyph Report',
        columns => ['Planet',(map { ucfirst($_) } ore_types()),'Total'],
    );
    
    my $cache_glyphs = { map { $_ => 0 } ore_types() };
    
    foreach my $planet_id ($self->my_planets) {
        my %planet_glyphs = $self->_report_glyph_planet($planet_id,$table);
        while (my ($glyph,$count) = each %planet_glyphs) {
            $cache_glyphs->{$glyph} += $count;
        }
    }
    
    # Write glyph cache
    $self->set_cache(
        key     => 'glyphs',
        value   => $cache_glyphs,
        max_age => (60*60*24),
    );
    
    return $table;
}

sub _report_glyph_planet {
    my ($self,$planet_id,$table) = @_;
    
    my $planet_stats = $self->my_body_status($planet_id);
    
    # Get archaeology ministry
    my $archaeology_ministry = $self->find_building($planet_stats->{id},'Archaeology');
    
    return
        unless defined $archaeology_ministry;
    
    # Get all glyphs
    my $archaeology_ministry_object = $self->build_object($archaeology_ministry);
    my $gylph_data = $self->request(
        object  => $archaeology_ministry_object,
        method  => 'get_glyphs',
    );
    
    my $total_glyphs = 0;
    my %all_glyphs = ( map { $_ => 0 } ore_types() );
    foreach my $glyph (@{$gylph_data->{glyphs}}) {
        $all_glyphs{$glyph->{type}} ++;
        $total_glyphs ++;
    }
    
    $table->add_row({
        planet  => $planet_stats->{name},
        total   => $total_glyphs,
        %all_glyphs,
    });
    
    return %all_glyphs;
}

no Moose::Role;
1;