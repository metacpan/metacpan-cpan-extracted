package DayDayUpX::Role::WithTags; # make CPAN happy

use MooseX::Declare;

role DayDayUpX::Role::WithTags {
    
    our $VERSION = '0.94';
    use DayDayUpX::Tag;

    has 'tags' => (
        is  => 'rw',
        isa => 'ArrayRef[DayDayUpX::Tag]',
        default => sub { [] },
        clearer => 'clear_tags',
    );
    
    method add_tag($name) {
        push @{$self->tags}, DayDayUpX::Tag->new( name => $name );
    };
};

1;