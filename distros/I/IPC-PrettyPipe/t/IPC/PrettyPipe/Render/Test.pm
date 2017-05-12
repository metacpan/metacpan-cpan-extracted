#!perl

package IPC::PrettyPipe::Render::Test;

use Carp;
use Template::Tiny;

use Moo;
use Types::Standard -all;

BEGIN {
    if ( $^O =~ /Win32/i ) {
        require Win32::Console::ANSI;
    }
}
use Term::ANSIColor ();


has pipe => (
    is       => 'rw',
    isa      => InstanceOf ['IPC::PrettyPipe'],
    required => 1,
);

has colors => (
    is      => 'rw',
    isa     => HashRef,
    default => sub {
        {
            cmd => {
                cmd    => 'blue',
                stream => {
                    spec => 'red',
                    file => 'green',
                },
                arg => {
                    name  => 'red',
                    sep   => 'yellow',
                    value => 'green',
                },
            },
            pipe => {
                stream => {
                    spec => 'red',
                    file => 'green',
                },
            },
        };
    },
);


has template => (

    is => 'rw',

    default => sub {
        return <<"EOT"
[% IF pipe.streams.empty %][% ELSE %](\t\\
[% END -%]
[%- FOREACH cmd IN pipe.cmds.elements %]
[%- IF cmd.first %]  [% ELSE %]\t\\
| [% END %][% color.cmd.cmd %][% cmd.cmd %][% color.reset %]
[%- FOREACH arg IN cmd.args.elements %]\t\\
    [% color.cmd.arg.pfx %][% arg.pfx %]
[%- color.cmd.arg.name %][% arg.name %]
[%- IF arg.has_value %][%- IF arg.sep %][% color.cmd.arg.sep %][% arg.sep %][% ELSE %] [% END %]
[%- color.cmd.arg.value %][% IF arg.has_blank_value%]''[% ELSE %][% arg.value %][% END %][% END %][% color.reset %]
[%- END %]
[%- FOREACH stream IN cmd.streams.elements %]\t\\
[% color.cmd.stream.spec %][% stream.spec %]
[%- IF stream.file %] [% END %][% color.cmd.stream.file %][% stream.file %][% color.reset %]
[%- END %]
[%- END %]
[%- IF pipe.streams.empty %][% ELSE %]\t\\
)[% FOREACH stream IN pipe.streams.elements %]\t\\
[% color.pipe.stream.spec %][% stream.spec -%]
[%- IF stream.file %] [% END %][% color.pipe.stream.file %][% stream.file %][% color.reset %]
[%- END %]
[%- END %]
EOT
    },


);

sub _colorize {

    my ( $tmpl, $colors ) = @_;

    ## no critic (ProhibitAccessOfPrivateData)

    while ( my ( $node, $value ) = each %$tmpl ) {

        if ( ref $value ) {

            $colors->{$node} = {};
            _colorize( $value, $colors->{$node} );

        }

        else {
            $colors->{$node} = Term::ANSIColor::color( $value );
        }

    }

}

sub render {

    my $self = shift;

    my ( $args ) = 
      validate( \@_,
		slurpy Dict[
			    colorize => Optional[ Bool ],
			   ]
	      );

    $args->{colorize} //= 1;

    my $output;

    my $colors = $self->colors;

    my %color;
    _colorize( $self->colors, \%color );

    $color{reset} = Term::ANSIColor::color( 'reset' )
      if keys %color;


    Template::Tiny->new->process(
        \$self->template,
        {
	 ## no critic (ProhibitAccessOfPrivateData)
            pipe => $self->pipe,
            $args->{colorize} ? ( color => \%color ) : (),
        },
        \$output,
    );

    return $output;
}

with 'IPC::PrettyPipe::Renderer';

1;

__END__
