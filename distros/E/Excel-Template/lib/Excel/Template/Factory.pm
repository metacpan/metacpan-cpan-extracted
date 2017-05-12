package Excel::Template::Factory;

use strict;

my %Manifest = (

# These are the instantiable nodes
    'IF'        => 'Excel::Template::Container::Conditional',
    'LOOP'      => 'Excel::Template::Container::Loop',
    'ROW'       => 'Excel::Template::Container::Row',
    'SCOPE'     => 'Excel::Template::Container::Scope',
    'WORKBOOK'  => 'Excel::Template::Container::Workbook',
    'WORKSHEET' => 'Excel::Template::Container::Worksheet',

    'BACKREF'     => 'Excel::Template::Element::Backref',
    'CELL'        => 'Excel::Template::Element::Cell',
    'FORMULA'     => 'Excel::Template::Element::Formula',
    'FREEZEPANES' => 'Excel::Template::Element::FreezePanes',
    'MERGE_RANGE' => 'Excel::Template::Element::MergeRange',
    'IMAGE'       => 'Excel::Template::Element::Image',
    'RANGE'       => 'Excel::Template::Element::Range',
    'VAR'         => 'Excel::Template::Element::Var',

    'FORMAT'    => 'Excel::Template::Container::Format',

# These are all the Format short-cut objects
# They are also instantiable
    'BOLD'      => 'Excel::Template::Container::Bold',
    'HIDDEN'    => 'Excel::Template::Container::Hidden',
    'ITALIC'    => 'Excel::Template::Container::Italic',
    'LOCKED'    => 'Excel::Template::Container::Locked',
    'OUTLINE'   => 'Excel::Template::Container::Outline',
    'SHADOW'    => 'Excel::Template::Container::Shadow',
    'STRIKEOUT' => 'Excel::Template::Container::Strikeout',

    'KEEP_LEADING_ZEROS' => 'Excel::Template::Container::KeepLeadingZeros',

# These are the helper objects
# They are also in here to make E::T::Factory::isa() work.
    'CONTEXT'    => 'Excel::Template::Context',
    'ITERATOR'   => 'Excel::Template::Iterator',
    'TEXTOBJECT' => 'Excel::Template::TextObject',

    'CONTAINER'  => 'Excel::Template::Container',
    'ELEMENT'    => 'Excel::Template::Element',

    'BASE'       => 'Excel::Template::Base',
);

my %isBuildable = map { $_ => ~~1 } qw(
    WORKBOOK WORKSHEET
    FORMAT BOLD HIDDEN ITALIC LOCKED OUTLINE SHADOW STRIKEOUT
    IF ROW LOOP SCOPE KEEP_LEADING_ZEROS
    CELL FORMULA FREEZEPANES IMAGE MERGE_RANGE
    VAR BACKREF RANGE
);

{
    my %Loaded;
    sub _load_class
    {
        my $self = shift;
        my ($class) = @_;

        unless ( exists $Loaded{$class} )
        {
            (my $filename = $class) =~ s!::!/!g;
            eval {
                require "$filename.pm";
            }; if ($@) {
                die "Cannot find or compile PM file for '$class' ($filename) because $@\n";
            }

            $Loaded{$class} = ~~1;
        }

        return ~~1;
    }
}

{
    my @param_names = qw(name class isa);
    sub register
    {
        my $self = shift;
        my %params = @_;

        for (@param_names)
        {
            unless ($params{$_})
            {
                warn "$_ was not supplied to register()\n" if $^W;
                return;
            }
        }

        my $name = uc $params{name};
        if (exists $Manifest{$name})
        {
            warn "$params{name} already exists in the manifest.\n" if $^W;
            return;
        }

        my $isa = uc $params{isa};
        unless (exists $Manifest{$isa})
        {
            warn "$params{isa} does not exist in the manifest.\n" if $^W;
            return;
        }

        {
            no strict 'refs';
            unshift @{"$params{class}::ISA"}, $Manifest{$isa};
        }

        $self->_load_class( $Manifest{$isa} );
        $self->_load_class( $params{class} );

        $Manifest{$name} = $params{class};
        $isBuildable{$name} = ~~1;

        return ~~1;
    }
}

sub _create
{
    my $self = shift;
    my $name = uc shift;

    return unless exists $Manifest{$name};

    $self->_load_class( $Manifest{$name} );
 
    return $Manifest{$name}->new(@_);
}

sub _create_node
{
    my $self = shift;
    my $name = uc shift;

    return unless exists $isBuildable{$name};

    return $self->_create($name, @_);
}

sub isa
{
    return unless @_ >= 2;
    exists $Manifest{uc $_[1]}
        ? UNIVERSAL::isa($_[0], $Manifest{uc $_[1]})
        : UNIVERSAL::isa(@_)
}

sub is_embedded
{
    return unless @_ >= 1;

    isa( $_[0], $_ ) && return ~~1 for qw( VAR BACKREF RANGE );
    return;
}

1;
__END__

=head1 NAME

Excel::Template::Factory - Excel::Template::Factory

=head1 PURPOSE

To provide a common way to instantiate Excel::Template nodes

=head1 USAGE

=head2 register()

Use this to register your own nodes.

Example forthcoming.

=head1 METHODS

=head2 isa

This is a customized isa() wrapper for syntactic sugar

=head2 is_embedded

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

=cut
