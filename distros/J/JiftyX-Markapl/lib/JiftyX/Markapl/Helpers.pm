package JiftyX::Markapl::Helpers;
use strict;
use warnings;

BEGIN {
    require Markapl;
    *outs_raw = \&Markapl::outs_raw;
    *outs = \&Markapl::outs
}

use base qw/Exporter/;

our @EXPORT = qw(hyperlink tangent redirect new_action form_submit
    form_return form_next_page request render_param render_hidden
    render_action render_region current_user
    get set );

sub current_user { Jifty->web->current_user }

sub request { Jifty->web->request }

sub _function_wrapper(@) {
    my $function = shift;
    Markapl->buffer->append(Jifty->web->$function(@_)->render || '');
    return '';
}

sub hyperlink(@) { _function_wrapper link     => @_ }
sub tangent(@)   { _function_wrapper tangent  => @_ }
sub redirect(@)  { _function_wrapper redirect => @_ }

sub new_action(@) { Jifty->web->new_action(@_);}

sub render_param {
    my $action = shift;
    outs_raw( $action->form_field(@_) );
    return '';
}

sub render_hidden {
    my $action = shift;
    outs_raw( $action->hidden(@_) );
    return ''
}

sub render_action(@) {
    my ( $action, $fields, $field_args ) = @_;

    my @f = ($fields && ref ($fields) eq 'ARRAY') ? @$fields : $action->argument_names;
    foreach my $argument (@f) {
        outs_raw( $action->form_field( $argument, %$field_args )->render );
    }
    '';
}

sub form_submit(@) {
    outs_raw( Jifty->web->form->submit(@_) );
    '';
}

sub form_return(@) {
    outs_raw( Jifty->web->form->return(@_) );
    '';
}

sub form_next_page(@) {
    Jifty->web->form->next_page(@_);
}

sub render_region(@) {
    unshift @_, 'name' if @_ % 2;
    my $args = {@_};
    my $path = $args->{path} ||= '/__jifty/empty';

    Jifty::Web::PageRegion->new(%$args)->render;
}

sub js_handlers(@) {}

{
    no warnings qw/redefine/;
    sub form (&) {
        my $code = shift;
        outs_raw( Jifty->web->form->start(@_) );
        $code->();
        outs_raw( Jifty->web->form->end );
        return '';
    }

    sub get {
        if (wantarray) {
            map { _get_single($_) } @_;
        } else {
            _get_single($_[0]);
        }
    }

    sub _get_single {
        my $v = request->template_argument($_[0]) || request->argument( $_[0] );
        return $v if defined $v;

        if (request->top_request ne request() and $v = request->top_request->template_argument($_[0])) {
            if (ref $v) {
                warn("The template argument '$_[0]' was not explicitly passed to the current region ('@{[request->path]}'), and thus will not work if the region is ever refreshed.  Unfortunately, it is a reference, so it can't be passed explicitly either.  You'll need to explicitly pass some stringification of what it is to the region.".Carp::longmess);
            } else {
                warn("The template argument '$_[0]' was not explicitly passed to the the current region ('@{[request->path]}'), and thus will not work if the region is ever refreshed.  Try passing it explicitly?");
            }
        }
    }

    sub set {
        while ( my ( $arg, $val ) = splice(@_, 0, 2) ) {
            request->template_argument( $arg => $val );
        }
    }
}


1;
