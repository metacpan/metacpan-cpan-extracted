package Games::Lacuna::Task::Report::Mining;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use Games::Lacuna::Client::Types qw(ore_types);
use List::Util qw(min max);

sub report_mining {
    my ($self) = @_;
    
    my $table = Games::Lacuna::Task::Table->new(
        headline=> 'Mining Report',
        columns => ['Planet','Level','Platforms','Capacity','Min','Max'],
    );
    
    foreach my $planet_id ($self->my_planets) {
       $self->_report_mining_body($planet_id,$table);
    }
    
    return $table;
}

sub _report_mining_body {
    my ($self,$planet_id,$table) = @_;
    
    my $planet_stats = $self->my_body_status($planet_id);
    
    # Get mining ministry
    my $mining = $self->find_building($planet_stats->{id},'MiningMinistry');
    
    return
        unless $mining;
    
    my $mining_object = $self->build_object($mining);
    
    my $mining_data = $self->request(
        object  => $mining_object,
        method  => 'view_platforms',
    );
    
    my @platforms;
    my $capcity = 0;
    foreach my $platform (@{$mining_data->{platforms}}) {
        my $total = 0;
        foreach my $ore (ore_types) {
            $total += $platform->{$ore.'_hour'};
        }
        push(@platforms,$total);
        $capcity ||= $platform->{shipping_capacity};
    }
    
    
    $table->add_row({
        planet          => $planet_stats->{name},
        level           => $mining->{level},
        platforms       => scalar(@{$mining_data->{platforms}}),
        capacity        => $capcity.'%',
        min             => min(@platforms),
        max             => max(@platforms),
    });
}

no Moose::Role;
1;