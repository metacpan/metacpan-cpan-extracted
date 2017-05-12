package TestApp::Action::RequireNoneOrAll;

use Form::Factory::Processor;

use_feature require_none_or_all => {
    groups => {
        one => [ qw(
            one
            two
            three
        ) ],
        two => [ qw(
            four
            five
            six
        ) ]
    },
};

has_control one   => ( control => 'text' );
has_control two   => ( control => 'text' );
has_control three => ( control => 'text' );
has_control four  => ( control => 'text' );
has_control five  => ( control => 'text' );
has_control six   => ( control => 'text' );
has_control seven => ( control => 'text' );

sub run { }

1;
