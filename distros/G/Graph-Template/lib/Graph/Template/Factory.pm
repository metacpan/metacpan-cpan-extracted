package Graph::Template::Factory;

use strict;

BEGIN {
    use vars qw(%Manifest %isBuildable);
}

%Manifest = (

# These are the instantiable nodes
#    'IF'   => 'Graph::Template::Container::Conditional',
#    'LOOP' => 'Graph::Template::Container::Loop',
    'DATA'  => 'Graph::Template::Container::Data',
    'GRAPH' => 'Graph::Template::Container::Graph',
    'SCOPE' => 'Graph::Template::Container::Scope',

    'DATAPOINT' => 'Graph::Template::Element::DataPoint',
    'TITLE'     => 'Graph::Template::Element::Title',
    'VAR'       => 'Graph::Template::Element::Var',
    'XLABEL'    => 'Graph::Template::Element::XLabel',
    'YLABEL'    => 'Graph::Template::Element::YLabel',

#    'FONT'      => 'Graph::Template::Container::Font',

# These are the helper objects

    'CONTEXT'    => 'Graph::Template::Context',
    'ITERATOR'   => 'Graph::Template::Iterator',
    'TEXTOBJECT' => 'Graph::Template::TextObject',

    'CONTAINER'  => 'Graph::Template::Container',
    'ELEMENT'    => 'Graph::Template::Element',

    'BASE'       => 'Graph::Template::Base',
);

while (my ($k, $v) = each %Manifest)
{
    (my $n = $v) =~ s!::!/!g;
    $n .= '.pm';

    $Manifest{$k} = {
        package  => $v,
        filename => $n,
    };
}

%isBuildable = map { $_ => undef } qw(
    DATA
    DATAPOINT
    GRAPH
    SCOPE
    TITLE
    VAR
    XLABEL
    YLABEL
);

sub register
{
    my %params = @_;

    my @param_names = qw(name class isa);
    for (@param_names)
    {
        unless ($params{$_})
        {
            warn "$_ was not supplied to register()\n";
            return 0;
        }
    }

    my $name = uc $params{name};
    if (exists $Manifest{$name})
    {
        warn "$params{name} already exists in the manifest.\n";
        return 0;
    }

    my $isa = uc $params{isa};
    unless (exists $Manifest{$isa})
    {
        warn "$params{isa} does not exist in the manifest.\n";
        return 0;
    }

    $Manifest{$name} = $params{class};
    $isBuildable{$name} = undef;

    {
        no strict 'refs';
        unshift @{"$params{class}::ISA"}, $Manifest{$isa};
    }

    return 1;
}

sub create
{
    my $class = shift;
    my $name = uc shift;

    return unless exists $Manifest{$name};

    eval {
        require $Manifest{$name}{filename};
    }; if ($@) {
        print "$@\n";
        die "Cannot find PM file for '$name' ($Manifest{$name}{filename})\n";
    }

    return $Manifest{$name}{package}->new(@_);
}

sub create_node
{
    my $class = shift;
    my $name = uc shift;

    return unless exists $isBuildable{$name};

    return $class->create($name, @_);
}

sub isa
{
    return unless @_ >= 2;
    exists $Manifest{uc $_[1]}
        ? UNIVERSAL::isa($_[0], $Manifest{uc $_[1]}{package})
        : UNIVERSAL::isa(@_)
}

1;
__END__
