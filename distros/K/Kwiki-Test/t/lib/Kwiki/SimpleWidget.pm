package Kwiki::SimpleWidget;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

const class_id             => 'simple_widget';

sub register {
    my $registry = shift;
    $registry->add(status => 'simple_widget',
                   template => 'simple_widget.html',
                   show_for => 'display',
               );
    super;
}

__DATA__
__template/tt2/simple_widget.html__
<!-- BEGIN simple_widget -->
<div id="simple_widget">
Simple Widget Is Gonna Get You Every Time
</div>
<!-- END simple_widget -->
