package Kwiki::Scode;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use GD;
our $VERSION = '0.03';

const class_id => 'scode';
const class_title => 'Scode prevents wiki spam';
const cgi_class => 'Kwiki::Scode::CGI';

field 'captcha_code';

my $tmpdir = "/tmp/";
my $scode_length = 6;
my $scode_maxtmp = 50;

sub register {
    my $reg = shift;
    $reg->add(action => 'captcha');
    $reg->add(hook => 'edit:edit', post => 'generate_scode');
    $reg->add(hook => 'edit:save', pre => 'check_scode');
}

sub generate_scode {
    my $hook = pop;
    my $scode = $self->hub->load_class('scode');
    srand int (time/10)+$$;
    my $code = int rand($scode->scode_tmp());
    $code++;
    $scode->scode_create($code);
    $scode->captcha_code($code);
    my ($html) = $hook->returned;
    my $img_html = $scode->template_process('scode_image.html', captcha_code => $code);
    $html =~ s{<textarea}{$img_html<textarea}s;
    return $html;
}

sub check_scode {
    my $hook = pop;
    my $scode = $self->hub->load_class('scode');
    unless($scode->scode_granted) {
        $hook->code(undef);
        return $self->redirect($self->redirect($self->pages->current->uri));
    }
}

sub scode_granted {
    my $answer = $self->scode_get($self->cgi->code);
    $answer eq $self->cgi->captcha;
}

sub captcha {
    my $code = $self->cgi->code;

    # Calculate code
    my $scode = $self->scode_get($code);

    # lets define the image
    my $im_length = ($self->scode_len()+1)*10;
    my $im = new GD::Image($im_length,25);

    # define the color we going to use
    my $c_background = $im->colorAllocate(224,224,224);
    my $c_border = $im->colorAllocate(0,0,0);
    my $c_line = $im->colorAllocate(192,192,192);
    my $c_code = $im->colorAllocate(128,128,128);

    # Fill in the background
    $im->fill(50,50,$c_background);

    # Draw the borders lines
    for (my $i=0;$i<$im_length;$i+=5) {
        $im->line($i,0,$i,24,$c_line);
    }

    for (my $i=0;$i<25;$i+=5) {
        $im->line(0,$i,$im_length-1,$i,$c_line);
    }

    $im->rectangle(0,0,$im_length-1,24,$c_border);

    # Write the code
    $im->string(gdGiantFont,8,5,$scode,$c_code);

    binmode STDOUT;
    for(qw(png jpeg gif)) {
        my $img = $im->$_;
        if($img) {
            $self->hub->headers->content_type("image/$_");
            $self->hub->headers->print;
            print $img;
            last;
        }
    }
    return;
}


## Following code comes from MT::Scode plugin ##########

sub scode_len {
    return $scode_length;
}

sub scode_tmp {
    return $scode_maxtmp;
}

sub scode_generate {
    return int rand( (10**($scode_length)) - (10**($scode_length-1)) ) +
                      10**($scode_length-1);
}

sub scode_create {
    my $code = shift;
    $tmpdir = $self->plugin_directory . '/';

    return if (-e $tmpdir.$code);

    if ($code>0 && $code<=$scode_maxtmp) {
    	my $scode = scode_generate();
        open(OUTFILE,">${tmpdir}${code}");
        print OUTFILE $scode;
        close(OUTFILE);
    }
}

sub scode_delete {
    my $code = shift;

    if ($code>0 && $code<=$scode_maxtmp) {
        unlink $tmpdir.$code;
    }
}

sub scode_get {
    my $code = shift;
    $tmpdir = $self->plugin_directory . '/';

    srand time;

    # Random number back...if have not initialized
    if ($code<=0 || $code>$scode_maxtmp || !-e $tmpdir.$code ) {
        return $self->scode_generate();
    }

    open(INFILE, $tmpdir.$code);
    my $scode = <INFILE>;
    close(INFILE);

    $scode =~ s/\D//g;
    return $scode;
}

package Kwiki::Scode::CGI;
use base 'Kwiki::CGI';

cgi 'code';
cgi 'captcha';

package Kwiki::Scode;

__DATA__

=head1 NAME

  Kwiki::Scode - Saves you from Wiki spammer.

=head1 INSTALLATION

The installation of this plugin is the same as every else's:

    # kwiki -install Kwiki::Scode

=head1 DESCRIPTION

Scode (or Captcha) is a facility to prevent web spammers from posting
abusing content to your website. Anyone who wants to edit wiki page
are now required to input a verification code from an image. Thus make
any spam-bot difficult to reconized that verifcation code.

This plugin make use most of C<MT::Scode> plugin code, and adapt to
C<Kwiki::Edit>, so it can help you if your site is suffered from
annoeying wiki spammers.

=head1 CREDITS

C<MT::Scode> Copyright (c) 2003, James Seng. (http://james.seng.cc/)

=head1 SEE ALSO

MT::Scode at http://james.seng.cc/archives/000145.html

For explanation of B<Captcha>, http://en.wikipedia.org/wiki/Captcha

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__template/tt2/scode_image.html__
<input type="hidden" name="code" value="[% captcha_code %]" />
<img src="[% script_name %]?action=captcha&code=[% captcha_code %]" />
<input type="text" maxlength="6" name="captcha" size="50" value="" />
<p class="description">Please enter the code as seen in the image above to post your comment.</p>
