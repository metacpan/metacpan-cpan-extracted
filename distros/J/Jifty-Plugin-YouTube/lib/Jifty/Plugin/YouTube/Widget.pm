use warnings;
use strict;
package Jifty::Plugin::YouTube::Widget;
use base qw(Jifty::Web::Form::Field);

# use Jifty::View::Declare::Helpers;

sub accessors { shift->SUPER::accessors() }

=head1 NAME

=cut


sub render_widget {
    my $self  = shift;

    my $field = '' ;
    my $current_value = $self->current_value;
    use Template::Declare;
    Template::Declare->init( roots => ['Jifty::Plugin::YouTube::View']);

    # to match
    # http://www.youtube.com/watch?v=
    #  9dOE0KhXTqo
    my $hash = '';
    if( $current_value =~ m/^\w{11}$/ ) {
        $hash = $1;
    }
    # http://www.youtube.com/watch?v=mAkrVWISiSc&feature=rec-HM-fresh+div
    elsif( $current_value =~ m{http://www.youtube.com/watch\?v=(\w{11})} ) {
        $hash = $1;
    }

    if( $hash ) {
        my $out = Template::Declare->show( 'youtube_widget', $hash );
        Jifty->web->out( $out );
    }
    # XXX: show an edit button here if not readonly 
    # and when hash is empty
    else {

    }
    return '';
}


1;
