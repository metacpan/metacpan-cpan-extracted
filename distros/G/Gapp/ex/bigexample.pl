#!/usr/bin/perl -w
use strict;
use warnings;



package Foo::Layout;

use Gapp::Layout;

extends 'Gapp::Layout::Default';

style 'Gapp::VBox' => sub {
    my ( $l, $w ) = @_;
    $w->properties->{spacing} ||= 6;
};

style 'Gapp::Window' => sub {
    my ( $l, $w ) = @_;
    $w->properties->{border_width} ||= 6;
};

style 'Gapp::Table' => sub {
    my ( $l, $w ) = @_;
    $w->properties->{column_spacing} ||= 6;
    $w->properties->{row_spacing} ||= 6;
};


package Track;

use Moose;

has 'number' => (
    is => 'rw',
    isa => 'Int',
    default => 0,
);

has 'title' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'album' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'artist' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);

has 'genre' => (
    is => 'rw',
    isa => 'Str',
    default => '',
);


has 'year' => (
    is => 'rw',
    isa => 'Int',
    default => '',
);



package main;

use Gapp;

# BUILD LIST OF SONGS

my @track_info = (
    [ 'Bessnectar', 'Divergent Spectrum', 'glitch.hop', 2011,
        [
            'Upside Down',
            'Plugged In (Rollz Remix)',
            'Immigraniada (Gogol Bordello Remix)',
            'Boomerang',
            'Lights (Ellie Goulding Remix)',
            'Probable Cause (ft. ill.Gates)',
            'Red Step (ft. Jantsen)',
            'The Matrix',
            'Voodoo',
            'Heads Up (2011 version)',
            'Paging Stereophonic',
            'Above & Beyond (ft. Seth Drake)',
            'Parade Into Centuries (2011 version)',
            'After Thought',
            'Disintegration Part IV (beatless)',
        ]
    ],
    [ 'Cake', 'Fashion Nugget', 'alternative', 1996,
        [
            "Frank Sinatra",
            "The Distance" ,
            "Friend Is a Four Letter Word" ,
            "Open Book",
            "Daria" ,
            "Race Car Ya-Yas",
            "I Will Survive" ,
            "Stickshifts and Safetybelts",
            "Perhaps, Perhaps, Perhaps",
            "It's Coming Down",
            "Nugget" ,
            "She'll Come Back to Me" ,
            "Italian Leather Sofa",
            "Sad Songs and Waltzes" ,
        ]
    ],
    [ 'Rusko', 'O.M.G', 'dubstep', 2010,
        [
            "Woo Boost",
            "Hold On" ,
            "Rubadub Shakedown",
            "Dial My Number",
            "I Love You",
            "Kumon Kumon",
            "Scareware",
            "Raver’s Special",
            "Feels So Real",
            "You’re On My Mind Baby",
            "Got Da Groove",
            "Oy",
            "My Mouth",
            "District Line",
        ]
    ],
    [ 'Steve Aoki', 'Wonderland', 'electro.house', 2011,
        [
            "Earthquakey People (feat. Rivers Cuomo)",
            "Ladi Dadi (feat. Wynter Gordon)",
            "Dangerous (feat. Zuper Blahq)",
            "Come with Me (Deadmeat) (feat. Polina)",
            "Emergency (feat. Lil Jon and Chiddy Bang)",
            "Livin' My Love (feat. LMFAO and NERVO)",
            "Control Freak (feat. Blaqstarr & My Name Is Kay)",
            "Steve Jobs (feat. Angger Dimas)",
            "Heartbreaker (feat. Lovefoxxx)",
            "Cudi the Kid (feat. Kid Cudi and Travis Barker)",
            "Ooh (feat. Rob Roy)",
            "The Kids Will Have Their Say (feat. Sick Boy with former members of The Exploited and Die Kreuzen)",
            "Earthquakey People (The Sequel) (feat. Rivers Cuomo)",
        ]
    ],
);

my @tracks; 
for ( @track_info ) {
    
    my ( $artist, $album,  $genre, $year, $tracks ) = @$_;
    
    my $i = 1;
    for my $t ( @$tracks ) {
        my $track = Track->new( artist => $artist, album => $album, year => $year, genre => $genre, number => $i, title => $t );
        push @tracks, $track;
        $i++;
    }
}


# create the GUI

use Gapp::Actions::Basic qw( Quit HideWindow );
use Gapp::Actions::Form qw( Cancel );

use Gapp::Actions -declare => [qw( New Edit Delete )];


my $ACTIVE_TRACK = undef;

my ( $form, $browser, $context, $model );

use Gapp::FormButtons;

$context = Gapp::Form::Context->new;
$context->add( 'track', sub { $ACTIVE_TRACK } );

sub build_form {
    Gapp::Window->new(
        layout => 'Foo::Layout',
        title => 'Edit Track',
        traits => [qw( Form )],
        context => $context,
        content => [
            Gapp::Table->new(
                map => qq(
                    +-[[--------+->>--------------------------------+
                    | Title     |  oooooooooooooooooooooooooooooo   |
                    +-[[--------+->>--------------------------------+
                    | Artist    |  oooooooooooooooooooooooooooooo   |
                    +-[[--------+->>--------------------------------+
                    | Album     |  oooooooooooooooooooooooooooooo   |
                    +-[[--------+-[[--------------------------------+
                    | Track No. |  oooo                             |
                    +-[[--------+-[[--------------------------------+
                    | Genre     |  oooo                             |
                    +-----------+-----------------------------------+
                    |                                 FormButtons   |
                    +-----------------------------------------------+
                ),
                content => [
                    Gapp::Label->new( text => 'Title' ),
                    Gapp::Entry->new( field => 'track.title' ),
                    
                    Gapp::Label->new( text => 'Artist' ),
                    Gapp::Entry->new( field => 'track.artist' ),
                    
                    Gapp::Label->new( text => 'Album' ),
                    Gapp::Entry->new( field => 'track.album' ),
                    
                    Gapp::Label->new( text => 'Track No.' ),
                    Gapp::SpinButton->new( field => 'track.number', width_chars => 2 ),
                    
                    Gapp::Label->new( text => 'Genre' ),
                    Gapp::ComboBox->new( field => 'track.genre',
                        values => [
                            undef,
                            'alternative',
                            'glitch.hop',
                            'dubstep',
                            'electro.house',
                        ]
                    ),
                    
                    Gapp::FormButtons->new,
                ],
            ),
        ],
        signal_connect => [
            ['gapp-form-apply' => sub {
                my ( $w, $args, $gtkw, $gtk_args ) = @_;
                $model->append_record
            }],
        ]
    );
}



action New => (
    label => 'New',
    tooltip => 'New Track',
    icon => 'gtk-add',
    code => sub {
        my ( $action, $w, $args, $gobj, $gargs ) = @_;
        
        my $form = build_form();
        $form->update;
        $form->show_all;
    }
);

action Edit => (
    label => 'Edit',
    mnemonic => '_Edit',
    tooltip => 'Edit Track',
    icon => 'gtk-edit',
    code => sub {
        my ( $action, $w, $args, $gobj, $gargs ) = @_;
        
        my $form = build_form();
        
        my $view = $w->toplevel->find('track-view');
        $ACTIVE_TRACK = $view->get_selected;
       
        $form->update;
        $form->show_all;
    }
);


$browser = Gapp::Window->new(
    title => 'Tag Editor',
    icon => 'gtk-media-play',
    default_size => [ 900, 400 ],
    content => [
        Gapp::VBox->new(
            content => [
                Gapp::MenuBar->new(
                    content => [
                        Gapp::MenuItem->new(
                            label => 'File',
                            menu => Gapp::Menu->new(
                                content => [
                                    Gapp::ImageMenuItem->new( action => Quit, accel_path =>  '<Gnumeric-Sheet>/File/Exit' ),
                                ]
                            )
                        ),
                        Gapp::MenuItem->new(
                            label => 'Edit',
                            menu => Gapp::Menu->new(
                                content => [
                                    Gapp::ImageMenuItem->new( action => New, accel_path =>  '<Gnumeric-Sheet>/File/Exit' ),
                                    Gapp::ImageMenuItem->new( action => Edit ),
                                    Gapp::ImageMenuItem->new( action => Delete ),
                                ]
                            )
                        ),
                    ],
                    expand => 0,
                ),
                Gapp::ScrolledWindow->new(
                    policy => [ 'automatic', 'automatic' ],
                    content => [
                        Gapp::TreeView->new(
                            name => 'track-view',
                            model => Gapp::Model::SimpleList->new(
                                content => \@tracks,
                            ),
                            columns => [
                                # name         title renderer  data-col  data-func
                                [ 'artist', 'Artist',  'text',        0,  'artist' ],
                                [ 'album' , 'Album' ,  'text',        0,  'album'  ],
                                [ '#'     , '#'     ,  'text',        0,  'number' ],
                                [ 'title' , 'Title' ,  'text',        0,  'title'  ],
                                [ 'year'  , 'Year'  ,  'text',        0,  'year'  ],
                                [ 'genre' , 'Genre' ,  'text',        0,  'genre'  ],
                            ],
                            signal_connect => [
                                [ 'row-activated' => Edit ]
                            ]
                        )
                    ]
                )
            ]
        ),
    ],
    signal_connect => [
        [ 'delete-event' => Quit ],
    ],
);

$browser->show_all;

Gapp->main;


