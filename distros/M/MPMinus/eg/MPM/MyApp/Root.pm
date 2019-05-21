package MPM::MyApp::Root; # $Id$
use strict;
use utf8;

=head1 NAME

MPM::MyApp::Root - Root controller (/)

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    GET /

=head1 DESCRIPTION

Root controller (/)

=head1 HISTORY

See C<Changes> file

=head1 SEE ALSO

L<MPMinus>

=head1 AUTHOR

Mr. Anonymous E<lt>root@localhostE<gt>

=head1 COPYRIGHT

Copyright (C) 2019 Mr. Anonymous. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = '1.00';

use Encode;
use Apache2::Const;
use Apache2::Access ();
use CGI -compile => qw/ :all /;
use CTK::Util qw/ :API /;
use Template;
use File::Spec::Functions qw/catfile catdir/;
use MPMinus::Util qw/getHiTime/;

use constant {
        DEFAULT_ENCODING        => 'utf8',
        DEFAULT_CONTENT_TYPE    => 'text/html; charset=utf-8',
        DEFAULT_TEMPLATE_DIR    => 'templates',
        DEFAULT_TEMPLATE_FILE   => 'root.tt',
    };

my ( $tt, $q, %usr, %output, @error, $actObject, $actEvent );

sub record {
    (
        -uri      => '/',

        -init     => \&hInit,
        -type     => \&hType,
        -fixup    => \&hFixup,
        -response => \&hResponse,
        -cleanup  => \&hCleanup,

        -meta     => {
            default => {
                handler => {
                    access => sub { 1 },    # expected DUAL rc
                    deny => sub { Apache2::Const::OK }, # expected DUAL rc
                    chck => \&default_chck, # expected BOOL rc
                    proc => \&default_proc, # expected HTTP rc
                    form => \&default_form, # expected HTTP rc
                },
                content_type    => DEFAULT_CONTENT_TYPE,
                template_file   => DEFAULT_TEMPLATE_FILE,
            },
        },
    )
}
sub hInit {
    my $self = shift;
    my $r = $self->r;

    # Variables
    %output = (); # Hash of output vars
    @error = ();  # Array of errors

    # CGI object & USeR parameters from URI query string or form/data
    $q = new CGI;
    %usr = ();
    foreach ($q->all_parameters) {
        $usr{$_} = $q->param($_);
        Encode::_utf8_on($usr{$_});
    }

    # Action variables
    ($actObject, $actEvent) = split /[,]/, $usr{action} || '';
    $actObject = 'default' unless $actObject && $self->ActionCheck($actObject);
    $actEvent  = $actEvent && $actEvent =~ /go/ ? 'go' : '';

    # Init Template-instance
    $tt ||= new Template({
        INCLUDE_PATH    => catdir($self->conf("modperl_root"), DEFAULT_TEMPLATE_DIR),
        DELIMITER       => CTK::Util::isostype('Windows') ? ';' : ':',
        ENCODING        => DEFAULT_ENCODING,
    }) or do {
        $self->log_error(sprintf("%s/%s> %s", $self->conf("project"), __PACKAGE__, $Template::ERROR));
        $r->notes->set('error-notes' => $Template::ERROR);
        return Apache2::Const::SERVER_ERROR;
    };

    return Apache2::Const::OK;
}
sub hType {
    my $self = shift;
    my $r = $self->r;

    $r->content_type($self->getActionRecord($actObject)->{content_type} || DEFAULT_CONTENT_TYPE);

    return Apache2::Const::OK;
}
sub hFixup {
    my $self = shift;

    %output = (
        project_name    => $self->conf("project"),
        mpminus_version => $self->VERSION,
        base_url        => $self->conf("url"),
    );

    return Apache2::Const::OK;
}
sub hResponse {
    my $self = shift;
    my $r = $self->r;

    # Run
    my $status = $self->ActionTransaction($actObject, $actEvent);
    return $status if $status == Apache2::Const::REDIRECT;

    # Stash debug_time
    $output{debug_time} = sprintf("%.4f", getHiTime() - $self->conf('hitime'));

    # Stash result
    $output{error} = [@error];
    my $tplfile = $self->getActionRecord($actObject)->{template_file} || DEFAULT_TEMPLATE_FILE;
    $tt->process($tplfile, \%output, sub {
            my $o = shift;
            $r->set_content_length(length(Encode::encode_utf8($o)) || 0);
            $r->print($o);
        }) || do {
        $self->log_error(sprintf("%s/%s> %s", $self->conf("project"), __PACKAGE__, $tt->error()));
        $r->notes->set('error-notes' => $tt->error());
        return Apache2::Const::SERVER_ERROR;
    };
    $r->rflush();

    return $status;
}
sub hCleanup {
    my $self = shift;

    undef $q;
    undef %usr;
    undef %output;
    undef @error;

    return Apache2::Const::OK;
}

# MVC SKEL level methods
sub default_chck {
    return @error ? 0 : 1
}
sub default_form {
    my $self = shift;
    my $r = $self->r;

    if ($usr{show} && $usr{show} eq 'errors') {
        push @error, "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Mi bibendum neque egestas congue quisque egestas diam. Nunc pulvinar sapien et ligula ullamcorper. Congue eu consequat ac felis donec et. Sit amet nulla facilisi morbi tempus iaculis urna id volutpat. Arcu ac tortor dignissim convallis aenean et tortor at. Adipiscing at in tellus integer feugiat scelerisque varius. At urna condimentum mattis pellentesque id nibh. Volutpat lacus laoreet non curabitur gravida. Varius duis at consectetur lorem donec massa sapien faucibus. Non enim praesent elementum facilisis leo. Viverra nam libero justo laoreet sit. Sagittis eu volutpat odio facilisis mauris sit. A diam maecenas sed enim. Platea dictumst quisque sagittis purus. Vel pharetra vel turpis nunc eget. Semper risus in hendrerit gravida rutrum quisque. Amet luctus venenatis lectus magna. Fermentum iaculis eu non diam phasellus. Integer malesuada nunc vel risus.";
        push @error, "Nunc mattis enim ut tellus elementum sagittis. Sit amet tellus cras adipiscing enim. Non sodales neque sodales ut. Nisi scelerisque eu ultrices vitae auctor eu. In est ante in nibh mauris. Volutpat commodo sed egestas egestas fringilla. Quam id leo in vitae turpis. Lectus arcu bibendum at varius vel pharetra vel turpis nunc. Orci a scelerisque purus semper eget duis at tellus at. Justo laoreet sit amet cursus sit amet dictum sit amet. Sed risus pretium quam vulputate dignissim suspendisse in est ante. Potenti nullam ac tortor vitae purus faucibus ornare suspendisse sed. Faucibus interdum posuere lorem ipsum dolor sit amet. Aliquet nec ullamcorper sit amet risus nullam eget felis eget. Tortor consequat id porta nibh venenatis cras. Dignissim convallis aenean et tortor at risus viverra adipiscing at. Mauris sit amet massa vitae tortor condimentum lacinia quis vel. Ut tortor pretium viverra suspendisse. Adipiscing tristique risus nec feugiat in fermentum posuere urna nec. Consectetur libero id faucibus nisl tincidunt eget.";
        push @error, "Risus sed vulputate odio ut enim blandit volutpat maecenas. Leo in vitae turpis massa sed. Dignissim cras tincidunt lobortis feugiat. Purus gravida quis blandit turpis cursus in. Gravida dictum fusce ut placerat orci. Fringilla est ullamcorper eget nulla facilisi etiam dignissim diam. Enim tortor at auctor urna nunc id cursus metus. Urna condimentum mattis pellentesque id nibh tortor id. Proin libero nunc consequat interdum. Euismod elementum nisi quis eleifend quam adipiscing vitae proin. Nisi est sit amet facilisis. Enim diam vulputate ut pharetra sit amet aliquam. Risus pretium quam vulputate dignissim suspendisse. Congue eu consequat ac felis donec et odio pellentesque diam. Risus commodo viverra maecenas accumsan lacus vel facilisis volutpat.";
    }

    return Apache2::Const::OK;
}
sub default_proc {
    my $self = shift;
    my $r = $self->r;

    $r->headers_out->set(Location => $self->conf('url').'/mpminfo');
    return Apache2::Const::REDIRECT;
}

1;

