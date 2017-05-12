package JQuery::Mobile;
use strict;
use warnings;
no warnings 'uninitialized';
use Exporter 'import';
our @EXPORT_OK = qw(new head header footer table panel popup page pages form listview collapsible collapsible_set navbar button controlgroup input rangeslider select checkbox radio textarea);

use Clone qw(clone);
use HTML::Entities qw(encode_entities);

our $VERSION = 0.03;
# 54.4

sub new {
	my ($class, %args) = (@_);
	my $self = bless {}, $class;
	$args{config} ||= {};
	
	$self->{config} = {
		'head' => 1, # include <html>, <head>, and <body> tag when rendering a page
		'viewport' => 'width=device-width, initial-scale=1', # default viewport
		'apple-mobile-web-app-capable' => 1,  # enable as apple web app
		'apple-touch-icon' => '', # path to apple web app icon image
		'apple-touch-icon-72' => '', # path to apple web app icon image (72x72 pixels)
		'apple-touch-icon-114' => '', # path to apple web app icon image (114x114 pixels)
		'apple-touch-startup-image' => '', # path to apple web app startup image
		'jquery-mobile-css' => 'http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.css',
		'jquery-mobile-js' => 'http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.js',
		'jquery' => 'http://code.jquery.com/jquery-1.9.1.min.js',
		'app-css' => [], # global application CSS files
		'app-js' => [], # global application JS files
		'app-inline-css' => '      span.invalid{color:#F00000;line-height: 1.5;}', # inline CSS code
		'app-inline-js' => '', # inline JS code
		'app-title' => '', # <title> in <head>
		# a list of default allowed HTML and data-* attributes for UI components (Reference: http://api.jquerymobile.com/data-attribute/)
		'header-footer-html-attribute' => ['id', 'class'],
		'header-footer-data-attribute' => ['id', 'fullscreen', 'position', 'theme'],
		'navbar-html-attribute' => ['id', 'class'],
		'navbar-data-attribute' => ['disable-page-zoom', 'enhance', 'fullscreen', 'iconpos', 'tap-toggle', 'theme', 'transition', 'update-page-padding', 'visible-on-page-show'],
		'navbar-item-html-attribute' => ['id', 'class', 'target'],
		'navbar-item-data-attribute' => ['ajax', 'icon', 'iconpos', 'iconshadow','prefetch', 'theme'],
		'page-html-attribute' => ['id', 'class'],
		# combine data-attributes for page and dialog
		'page-data-attribute' => ['add-back-btn', 'back-btn-text', 'back-btn-theme', 'close-btn', 'close-btn-text', 'corners', 'dom-cache', 'enhance', 'overlay-theme', 'role', 'shadow','theme', 'title', 'tolerance', 'url'],
		'table-html-attribute' => ['id', 'class'],
		'table-data-attribute' => ['mode'],
		'table-head-html-attribute' => ['id', 'class'],
		'table-head-data-attribute' => ['priority'],
		'panel-html-attribute' => ['id', 'class'],
		'panel-data-attribute' => ['corners', 'overlay-theme', 'shadow', 'theme', 'tolerance', 'position-to', 'rel', 'role', 'transition'],
		'popup-html-attribute' => ['id', 'class'],
		'popup-data-attribute' => ['animate', 'dismissible', 'display', 'position', 'position-fixed', 'swipe-close', 'role', 'theme'],
		'listview-html-attribute' => ['id', 'class'],
		'listview-data-attribute' => ['autodividers', 'count-theme', 'divider-theme', 'enhance', 'filter', 'filter-placeholder', 'filter-reveal', 'filter-theme', 'filtertext', 'header-theme', 'inset', 'split-icon', 'split-theme', 'theme'],
		'listview-item-html-attribute' => ['id', 'class'],
		'listview-item-data-attribute' => ['ajax', 'mini', 'rel', 'theme', 'transition'],
		'collapsible-html-attribute' => ['id', 'class'],
		'collapsible-data-attribute' => ['collapsed', 'collapsed-icon', 'content-theme', 'expanded-icon', 'iconpos', 'inset', 'mini', 'theme'],
		'collapsible-set-html-attribute' => ['id', 'class'],
		'collapsible-set-data-attribute' => ['collapsed-icon', 'content-theme', 'expanded-icon', 'iconpos', 'inset', 'mini', 'theme'],
		'controlgroup-html-attribute' => ['id', 'class'],
		'controlgroup-data-attribute' => ['enhance', 'iconpos', 'mini', 'theme', 'type'],
		'button-html-attribute' => ['id', 'name', 'class', 'maxlength', 'size', 'type', 'value'],
		'button-html-anchor-attribute' => ['id', 'class', 'href', 'target'],
		'button-data-attribute' => ['ajax', 'corners', 'dialog', 'direction', 'dom-cache', 'external', 'icon', 'iconpos', 'iconshadow', 'inline', 'mini', 'position-to', 'prefetch', 'rel', 'role', 'shadow', 'theme', 'transition'],
		'form-html-attribute' => ['id', 'action', 'class', 'enctype', 'method'],
		'form-data-attribute' => ['enhance', 'theme', 'ajax'],
		'input-html-attribute' => ['id', 'class', 'disabled', 'max', 'maxlength', 'min', 'name', 'pattern', 'placeholder', 'readonly', 'required', 'size', 'type', 'value', 'accept', 'capture'],
		'input-data-attribute' => ['clear-btn', 'clear-btn-text', 'corners', 'highlight', 'icon', 'iconpos', 'iconshadow', 'inline', 'mini', 'shadow', 'theme', 'track-theme'],
		'textarea-html-attribute' => ['id', 'name', 'class', 'rows', 'cols', 'readonly', 'disabled', 'title', 'required', 'placeholder', 'title', 'pattern'],
		'textarea-data-attribute' => ['clear-btn', 'clear-btn-text', 'mini', 'theme'],
		'select-html-attribute' => ['id', 'class', 'size', 'maxlength', 'readonly', 'disabled', 'title', 'required', 'placeholder', 'title', 'pattern', 'multiple'],
		'select-data-attribute' => ['icon', 'iconpos', 'inline', 'mini', 'native-menu', 'overlay-theme', 'theme', 'role'],
		'radio-checkbox-html-attribute' => ['id', 'class', 'readonly', 'disabled', 'title', 'required', 'placeholder', 'title', 'pattern', 'value'],
		'radio-checkbox-data-attribute' => ['mini', 'theme'],
		'rangeslider-html-attribute' => ['id', 'name', 'class'],
		'rangeslider-data-attribute' => ['highlight', 'mini', 'theme', 'track-theme'],
		'label' => sub {
			my $args = shift;
			return '<strong>' . $args->{label} . '</strong>' if $args->{required};
			return $args->{label};
		},
		'invalid' => sub {
			my $args = shift;
			my $message = $args->{message};

			if (! $message && $args->{type}) {
				$message = {
					'input' => 'Enter "%FIELDNAME%"',
					'checkbox' => 'Check one or more "%FIELDNAME%"',
					'radio' => 'Choose "%FIELDNAME%"',
					'select' => 'Select an option from "%FIELDNAME%"',
					'textarea' => 'Fill in the "%FIELDNAME%"'
				}->{$args->{type}};
			}

			$message ||= 'Enter "%FIELDNAME%"';
			$message =~ s/\%FIELDNAME\%/$args->{label}/g;

			return '<span class="invalid">' . $message . '</span>' if $args->{invalid};
		},
		%{$args{config}},
	};

	return $self;
}

sub head {
	my ($self, %args) = @_;

	my $head = '  <head>' . "\n" . '    <title>' . $self->{config}->{'app-title'} . '</title>' . "\n" . 
	'    <meta name="viewport" content="' . $self->{config}->{'viewport'} . '" />' . "\n";
	# apple icons, startup image
	$head .= '    <meta name="apple-mobile-web-app-capable" content="yes" />' . "\n" if $self->{config}->{'apple-mobile-web-app-capable'};
	$head .= '    <link rel="apple-touch-icon" href="' . $self->{config}->{'apple-touch-icon'} . '" />' . "\n" if $self->{config}->{'apple-touch-icon'};
	$head .= '    <link rel="apple-touch-icon" sizes="72x72" href="' . $self->{config}->{'apple-touch-icon-72'} . '" />' . "\n" if $self->{config}->{'apple-touch-icon-72'};
	$head .= '    <link rel="apple-touch-icon" sizes="114x114" href="' . $self->{config}->{'apple-touch-icon-114'} . '" />' . "\n" if $self->{config}->{'apple-touch-icon-114'};
	$head .= '    <link rel="apple-touch-startup-image" href="' . $self->{config}->{'apple-touch-startup-image'} . '" />' . "\n" if $self->{config}->{'apple-touch-startup-image'};

	my $css_sources = [$self->{config}->{'jquery-mobile-css'}];
	push @{$css_sources}, @{$self->{config}->{'app-css'}}, if @{$self->{config}->{'app-css'}};

	foreach my $css (@{$css_sources}) {
		$head .= '    <link rel="stylesheet" href="' . $css . '" />' . "\n";
	}

	my $js_sources = [$self->{config}->{'jquery'}, $self->{config}->{'jquery-mobile-js'}];
	push @{$js_sources}, @{$self->{config}->{'app-js'}}, if @{$self->{config}->{'app-js'}};

	foreach my $js (@{$js_sources}) {
		$head .= '    <script src="' . $js . '"></script>' . "\n" if $js;
	}

	$head .= '    <style>' . "\n" . $self->{config}->{'app-inline-css'} . "\n" . '    </style>' . "\n" if $self->{config}->{'app-inline-css'};
	$head .= '    <script type="text/javascript">' . "\n" . $self->{config}->{'app-inline-js'} . "\n" . '    </script>' . "\n" if $self->{config}->{'app-inline-js'};

	$head .= '  </head>' . "\n";
	return $head;
}

sub header {
	my ($self, %args) = @_;

	$args{content} ||= '      <h1>' . ($self->{config}->{'app-title'} || 'Header Content') . '</h1>';
	
	my $attributes = $self->_header_footer_attribute('header', \%args);
	my $header = '      <div data-role="header"'. $attributes . '>' . "\n";
	$header .= $args{content} . "\n";
	$header .= '      </div><!-- /header -->' . "\n";
	return $header;
}

sub footer {
	my ($self, %args) = @_;

	$args{content} ||= '      <h4>Footer Content</h4>';

	my $attributes = $self->_header_footer_attribute('footer', \%args);
	my $footer = '      <div data-role="footer"' . $attributes . '>' . "\n";
	$footer .=  $args{content} . "\n";
	$footer .= '      </div><!-- /footer -->' . "\n";
	return $footer;
}

sub navbar {
	my ($self, %args) = @_;


	my $attributes = _html_attribute('', $self->{config}->{'navbar-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'navbar-data-attribute'}, \%args);

	my $navbar = '        <div data-role="navbar"'. $attributes . '>' . "\n";
	$navbar .= '          <ul>' . "\n";

	foreach my $item (@{$args{items}}) {
		my $item_attributes = _data_attribute ('', $self->{config}->{'navbar-item-data-attribute'}, $item);

		my $item_class = '';

		if ($args{active}) {
			if ($item->{$args{active}->{option}} eq $args{active}->{value}) {
				if ($item->{class}) {
					$item->{class} .= ' ui-btn-active';
					$item->{class} .= ' ui-btn-persist' if $args{persist};
				}
				else {
					$item->{class} = 'ui-btn-active';
					$item->{class} .= ' ui-btn-persist' if $args{persist};
				}
			}
		}
		elsif ($item->{active}) {
			if ($item->{class}) {
				$item->{class} .= ' ui-btn-active';
				$item->{class} .= ' ui-btn-persist' if $item->{persist};
			}
			else {
				$item->{class} = 'ui-btn-active';
				$item->{class} .= ' ui-btn-persist' if $item->{persist};
			}
		}

		$item_attributes = _html_attribute ($item_attributes, $self->{config}->{'navbar-item-html-attribute'}, $item);

		$navbar .= '            <li><a href="' . $item->{href} . '"' . $item_attributes . '>' . $item->{value} . '</a></li>' . "\n";

	}
	$navbar .= '          </ul>' . "\n";
	$navbar .= '        </div><!-- /navbar -->';
	return $navbar;
}

sub panel {
	my ($self, %args) = @_;

	$args{content} ||= '          <p>Panel Content</p>';
	$args{role} = 'panel';

	my $attributes = _html_attribute('', $self->{config}->{'panel-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'panel-data-attribute'}, \%args);

	my $panel = '        <div' . $attributes . '>' . "\n";
	$panel .= $args{content} . "\n";
	$panel .= '        </div><!-- /panel -->' . "\n";

	return $panel;
}

sub table {
	my ($self, %args) = @_;

	unless ($args{content}) {

		$args{content} =  '          <thead>' . "\n" . '            <tr>' . "\n";
		foreach my $header (@{$args{headers}}) {

			my $head_attributes = '';
			if ($args{th} && exists $args{th}->{$header}) {
				$head_attributes = _html_attribute($head_attributes, $self->{config}->{'table-head-html-attribute'}, $args{th}->{$header});
				$head_attributes = _data_attribute($head_attributes, $self->{config}->{'table-head-data-attribute'}, $args{th}->{$header});
			}

			$args{content} .= '              <th' . $head_attributes . '>' . $header . '</th>' . "\n";
		}
		$args{content} .=  '            </tr>' . "\n" . '          </thead>' . "\n";

		$args{content} .=  '          <tbody>'. "\n";
		foreach my $row (@{$args{rows}}) {
			$args{content} .=  '            <tr>' . "\n" . join("\n", map ({'              <td>' . $_ . '</td>'} @{$row})) . "\n" . '            </tr>' . "\n";
		}
		$args{content} .=  '          </tbody>';
	}

	my $attributes = _html_attribute('', $self->{config}->{'table-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'table-data-attribute'}, \%args);

	my $table = '        <table data-role="table"' . $attributes . '>' . "\n" . $args{content} . "\n" . '        </table>' . "\n";
	return $table;
}

sub popup {
	my ($self, %args) = @_;

	$args{content} ||= '          <p>Popup Content</p>';
	$args{role} = 'popup';

	my $attributes = _html_attribute('', $self->{config}->{'popup-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'popup-data-attribute'}, \%args);

	my $popup = '        <div' . $attributes . '>' . "\n";
	$popup .= $args{content} . "\n";
	$popup .= '        </div><!-- /popup -->' . "\n";

	return $popup;
}

sub page {
	my ($self, %args) = @_;

	$args{content} ||= '        <p>Page Content</p>';
	$args{role} ||= 'page';

	my $attributes = _html_attribute('', $self->{config}->{'page-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'page-data-attribute'}, \%args);

	my $page = '    <div' . $attributes . '>' . "\n";
	$page .= $self->header(%{$args{header}}) if $args{header};
	$page .= $self->panel(%{$args{panel}}) if $args{panel};
	$page .= '      <div data-role="content">' . "\n" . $args{content} . "\n" . '      </div><!-- /content -->' . "\n";
	$page .= $args{after} if $args{after};
	$page .= $self->footer(%{$args{footer}}) if $args{footer};
	$page .= '    </div><!-- /page -->' . "\n";

	return $page if (exists $args{head} && ! $args{head}) || ! $self->{config}->{'head'};
	return "<!DOCTYPE html>\n<html>\n" . $self->head() . "  <body>\n" . $page . "  </body>\n</html>";
}

sub pages {
	my ($self, %args) = @_;

	my $pages = '';	

	foreach my $page (@{$args{pages}}) {
		$page->{head} = 0;
		$pages .= $self->page(%{$page});
	}

	$pages ||= '<p>Multiple Pages</p>';

	return $pages if (exists $args{head} && ! $args{head}) || ! $self->{config}->{'head'};
	return "<!DOCTYPE html>\n<html>\n" . $self->head() . "  <body>\n" . $pages . "  </body>\n</html>";
}

sub collapsible_set {
	my ($self, %args) = @_;

	if ($args{collapsibles} && @{$args{collapsibles}}) {
		foreach my $collapsible (@{$args{collapsibles}}) {
			if ($args{active} && ! exists $collapsible->{active}) {
				$collapsible->{active} = $args{active};
			}

			$args{content} .= $self->collapsible(%{$collapsible});
		}
	}
	else {
		$args{content} ||= '          <p>Collapsible Set Content</p>';	
	}	

	my $attributes = _html_attribute('', $self->{config}->{'collapsible-set-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'collapsible-set-data-attribute'}, \%args);

	my $collapsible_set = '        <div data-role="collapsible-set"' . $attributes . '>' . "\n" . $args{content} . "\n" . '        </div>' . "\n";
	return $collapsible_set;
}

sub collapsible {
	my ($self, %args) = @_;

	if ($args{listview}) {
		if ($args{active} && ! exists $args{listview}->{active}) {
			$args{listview}->{active} = $args{active};
		}

		$args{title} ||= 'Title';
		$args{content} = '          <h1>' . $args{title} . '</h1>' . "\n" . $self->listview(%{$args{listview}});
		$args{collapsed} = 'false' if ! exists $args{collapsed} && $args{content} =~ /ui-btn-active/;
	}
	else {
		$args{content} ||= '            <h1>Collapsible Title</h1><p>Collapsible Content</p>';
	}

	my $attributes = _html_attribute('', $self->{config}->{'collapsible-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'collapsible-data-attribute'}, \%args);

	my $collapsible = '          <div data-role="collapsible"' . $attributes . '>' . "\n" . $args{content} . "\n" . '          </div>' . "\n";
	return $collapsible;
}

sub listview {
	my ($self, %args) = @_;

	my $attributes = _html_attribute('', $self->{config}->{'listview-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'listview-data-attribute'}, \%args);

	my $anchor_attributes = '';
	if ($args{anchor} && %{$args{anchor}}) {
		$anchor_attributes = _html_attribute($anchor_attributes, $self->{config}->{'button-html-anchor-attribute'}, $args{anchor});
		$anchor_attributes = _data_attribute($anchor_attributes, $self->{config}->{'button-data-attribute'}, $args{anchor});
	}

	my $split_anchor_attributes = '';
	if ($args{split_anchor} && %{$args{split_anchor}}) {
		$split_anchor_attributes = _html_attribute($split_anchor_attributes, $self->{config}->{'button-html-anchor-attribute'}, $args{split_anchor});
		$split_anchor_attributes = _data_attribute($split_anchor_attributes, $self->{config}->{'button-data-attribute'}, $args{split_anchor});
	}

	my $list_tag;
	if ($args{numbered}) {
		$list_tag = 'ol';
	}
	else {
		$list_tag = 'ul';	
	}

	my $list = '        <' . $list_tag . ' data-role="listview"' . $attributes . '>' . "\n";
	
	my $divider = ''; 

	foreach my $item (@{$args{items}}) {

		if ($item->{divider}) {
			$list .= '          <li data-role="list-divider">' . $item->{value} . '</li>' . "\n";
			next;
		}

		my $item_attributes = _data_attribute ('', $self->{config}->{'listview-item-data-attribute'}, $item);
		if ($args{active}) {
			if ($item->{$args{active}->{option}} eq $args{active}->{value}) {
				if ($item->{class}) {
					$item->{class} .= ' ui-btn-active';
				}
				else {
					$item->{class} = 'ui-btn-active';
				}
			}
		}
		elsif ($item->{active}) {
			if ($item->{class}) {
				$item->{class} .= ' ui-btn-active';
			}
			else {
				$item->{class} = 'ui-btn-active';
			}
		}

		$item_attributes = _html_attribute ($item_attributes, $self->{config}->{'listview-item-html-attribute'}, $item);

		my $value = '';

		if (defined $item->{content}) {
			$value = $item->{content};
		}
		elsif (defined $item->{value}) {
			$value = '<p>' . $item->{value} . '</p>';
		}

		if (defined $item->{title}) {
			$value = '<h3>' . $item->{title} . '</h3>' . $value;
		}

		if (defined $item->{count}) {
			$value .= '<span class="ui-li-count">' . $item->{count} . '</span>';
		}

		if (defined $item->{aside}) {
			$value .= '<p class="ui-li-aside">' . $item->{aside} . '</p>';
		}

		if ($item->{divider}) {
			$list .= '          <li' . $item_attributes . ' data-role="list-divider">' . $value . '</li>' . "\n";
		}
		elsif (defined $item->{list}) {
			$list .= '<li' . $item_attributes . '>' . $value . "\n" . $item->{list} . '</li>' . "\n";
		}
		elsif (defined $item->{href}) {
			$value = '<img src="' . $item->{image} . '" />' . $value if defined $item->{image};
			$value = '<a'. $anchor_attributes . ' href="' . $item->{href} . '">' . $value . '</a>';

			if (defined $item->{split}) {
				my $split_value = $item->{split_value} || $args{split_value};
				$value .= '<a'. $split_anchor_attributes . ' href="' . $item->{split} . '">' . $split_value . '</a>';
			}

			$list .= '          <li' . $item_attributes . '>' . $value . '</li>' . "\n";
		}
		elsif (defined $item->{image}) {
			$list .= '          <li' . $item_attributes . '><img src="' . $item->{image} . '" />' . $value . '</li>' . "\n";
		}
		else {
			$list .= '          <li' . $item_attributes . '>' . $value . '</li>' . "\n";
		}
	}
	$list .= '        </' . $list_tag . '>' . "\n";
	return $list;
}

sub controlgroup {
	my ($self, %args) = @_;

	my $attributes = _html_attribute('', $self->{config}->{'controlgroup-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'controlgroup-data-attribute'}, \%args);

	my $element = $args{fieldset} ? 'fieldset' : 'div';

	my $controlgroup = '          <' . $element . ' data-role="controlgroup"'. $attributes . '>' . "\n";
	$controlgroup .= '          ' . $args{content} . "\n";
	$controlgroup .= '          </' . $element . '><!-- /controlgroup -->' . "\n";
	return $controlgroup;
}

sub button {
	my ($self, %args) = @_;

	unless (exists $args{role} && $args{role} eq 'none') {
		$args{role} = 'button';
	}

	my $attributes = _data_attribute('', $self->{config}->{'button-data-attribute'}, \%args);

	if ($args{type} && $args{type} =~ /^(button|submit|reset)$/) {
		$attributes = _html_attribute($attributes, $self->{config}->{'button-html-attribute'}, \%args);
		return '          <input' . $attributes . '/>' . "\n";
	}
	else {
		$attributes = _html_attribute($attributes, $self->{config}->{'button-html-anchor-attribute'}, \%args);
		return '          <a' . $attributes . '>' .  $args{value} . '</a>' . "\n";
	}
}

sub form {
	my ($self, %args) = @_;

	$args{method} ||= 'post';

	my $attributes = _html_attribute('', $self->{config}->{'form-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'form-data-attribute'}, \%args);

	my $content = '';

	if ($args{fields}) {
		foreach my $field (@{$args{fields}}) {
			if ($field->{type} && $field->{type} =~ /^(select|radio|checkbox|textarea|rangeslider)$/) {
				my $type = delete $field->{type};
				$content .= $self->$type(%{$field});
			}
			else {
				$content .= $self->input(%{$field});
			}
		}
	}

	my $buttons = '';

	if ($args{buttons}) {
		foreach my $button (@{$args{buttons}}) {
			$buttons .= $self->button(%{$button});
		}

		if ($args{controlgroup}) {
			my $controlgroup;
			if (ref $args{controlgroup} eq 'HASH') {
				$controlgroup = $args{controlgroup};
				$controlgroup->{content} = $buttons;
			}
			else {
				$controlgroup = {content => $buttons};
			}
			$content .= $self->controlgroup(%{$controlgroup});
		}
		else {
			$content .= $buttons;
		}
	}

	my $form = '        <form'. $attributes . '>' . "\n";
	$form .= '          <h1>' . $args{title} . "</h1>\n" if $args{title};
	$form .= '          <p>' . $args{description} . "</p>\n" if $args{description};
	$form .= $content;
	$form .= '        </form><!-- /form -->' . "\n";
	return $form;
}

sub rangeslider {
	my ($self, %args) = @_;

	my $attributes = _html_attribute('', $self->{config}->{'rangeslider-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'rangeslider-data-attribute'}, \%args);

	$args{from}->{type} = 'range';
	$args{to}->{type} = 'range';
	my $from = '              ' . $self->_input(%{$args{from}}) . "\n";
	my $to = '              ' . $self->_input(%{$args{to}});

	$args{container_role} ||= 'fieldcontain';
	my $invalid = $args{invalid} ? $self->{config}->{invalid}->(\%args) : '';

	my $rangeslider = '          <div data-role="' . $args{container_role} . '">' . "\n" . '            <div data-role="rangeslider"' . $attributes . '>' . "\n";
	$rangeslider .= $from . $to . $invalid . "\n";
	$rangeslider .= "            </div>\n          </div>\n";

	return $rangeslider;
}

sub _input {
	my ($self, %args) = @_;
	$args{type} ||= 'text';
	$args{id} ||= $args{name};
	$args{label} ||= _label($args{name});

	$args{value} = encode_entities($args{value});

	my $attributes = _html_attribute('', $self->{config}->{'input-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'input-data-attribute'}, \%args);

	return '          <input' . $attributes . ' />' . "\n" if $args{type} eq 'hidden';
	return '<label for="' . $args{id} . '">' . $self->{config}->{label}->(\%args) .  ':</label><input' . $attributes . ' />';
}

sub input {
	my ($self, %args) = @_;

	my $input = $self->_input(%args);
	return $input if $args{type} eq 'hidden';

	$args{container_role} ||= 'fieldcontain';
	my $invalid = $args{invalid} ? $self->{config}->{invalid}->(\%args) : '';
	return '          <div data-role="' . $args{container_role} . '">' . $input . $invalid . '</div>' . "\n";
}

sub textarea {
	my ($self, %args) = @_;

	$args{id} ||= $args{name};
	$args{label} ||= _label($args{name});

	$args{cols} ||= 40;
	$args{rows} ||= 8;
	$args{value} = encode_entities($args{value});

	my $attributes = _html_attribute('', $self->{config}->{'textarea-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'textarea-data-attribute'}, \%args);

	$args{container_role} ||= 'fieldcontain';
	my $invalid = $args{invalid} ? $self->{config}->{invalid}->(\%args) : '';
	return '          <div data-role="' . $args{container_role} . '"><label for="' . $args{id} . '">' . $self->{config}->{label}->(\%args) .  ':</label><textarea' . $attributes . '>' . $args{value} . '</textarea>' . $invalid . '</div>' . "\n";
}

sub select {
	my ($self, %args) = @_;

	$args{id} ||= $args{name};
	$args{label} ||= _label($args{name});

	if ($args{multiple}) {
		$args{'native-menu'} ||= 'false';
	}

	my $attributes = _html_attribute('', $self->{config}->{'select-html-attribute'}, \%args);
	$attributes = _data_attribute($attributes, $self->{config}->{'select-data-attribute'}, \%args);

	my $options = '';
	my $placeholder_text = $args{placeholder_text};

	if (ref $args{options} eq 'HASH') {

		my @keys;
		my $sort_options = $args{sort_options}; 
		if ($sort_options && $sort_options eq 'key') {
			@keys = sort keys %{$args{options}};
		}
		else {
			@keys = sort {$args{options}->{$a} cmp $args{options}->{$b}} keys %{$args{options}};
		}

		foreach my $key (@keys) {
			my $selected = '';

			if (defined $args{value}) {

				if (ref $args{value} eq 'HASH') {
					foreach my $value_key (keys %{$args{value}}) {
						if ($key eq $value_key) {
							$selected = 'selected="selected"';
							last;
						}
					}
				}
				elsif ($key eq $args{value}) {
					$selected = 'selected="selected"';
				}
			}

			$options .= '<option value="' . $key . '" ' . $selected . '>' . encode_entities($args{options}->{$key}) . '</option>';
		}

		if (defined $placeholder_text) {
			$options = '<option value="">' . encode_entities($placeholder_text) . '</option>' . $options;
		}
	}
	elsif (ref $args{options} eq 'ARRAY') {
		foreach my $option (@{$args{options}}) {
			my $selected = '';

			if (defined $args{value}) {

				if (ref $args{value} eq 'ARRAY') {
					foreach my $element (@{$args{value}}) {
						if ($option eq $element) {
							$selected = 'selected="selected"';
							last;
						}
					}
				}
				elsif ($option eq $args{value}) {
					$selected = 'selected="selected"';
				}
			}

			$options .= '<option value="' . $option . '" ' . $selected . '>' . encode_entities($option) . '</option>';
		}

		if (defined $placeholder_text) {
			$options = '<option value="">' . encode_entities($placeholder_text) . '</option>' . $options;
		}
	}
	else {
		$options = $args{options};
	}

	$args{container_role} ||= 'fieldcontain';
	my $invalid = $args{invalid} ? $self->{config}->{invalid}->(\%args) : '';
	return '          <div data-role="' . $args{container_role} . '"><label for="' . $args{id} . '">' . $self->{config}->{label}->(\%args) .  ':</label><select name="' . $args{name} . '"' . $attributes . '>' . $options . '</select>' . $invalid . '</div>' . "\n";
}

sub radio {
	my ($self, %args) = @_;

	$args{type} = 'radio';
	return $self->_radio_checkbox(%args);
}

sub checkbox {
	my ($self, %args) = @_;

	$args{type} = 'checkbox';
	return $self->_radio_checkbox(%args);
}

sub _radio_checkbox {
	my ($self, %args) = @_;

	$args{id} ||= $args{name};
	$args{label} ||= _label($args{name});

	my $data_attributes = _data_attribute('', $self->{config}->{'radio-checkbox-data-attribute'}, \%args);
	my $cloned_args = clone(\%args);
	my $options = '';

	if (ref $args{options} eq 'HASH') {

		my @keys;
		my $sort_options = $args{sort_options}; 
		if ($sort_options && $sort_options eq 'key') {
			@keys = sort keys %{$args{options}};
		}
		else {
			@keys = sort {$args{options}->{$a} cmp $args{options}->{$b}} keys %{$args{options}};
		}

		foreach my $key (@keys) {
			$cloned_args->{id} = $args{name} . '-' . _id($key);
			$cloned_args->{value} = $key;
			my $html_attributes = _html_attribute('', $self->{config}->{'radio-checkbox-html-attribute'}, $cloned_args);

			my $checked = '';

			if (defined $args{value}) {

				if (ref $args{value} eq 'HASH') {
					foreach my $value_key (keys %{$args{value}}) {
						if ($key eq $value_key) {
							$checked = ' checked="checked"';
							last;
						}
					}
				}
				elsif ($key eq $args{value}) {
					$checked = ' checked="checked"';
				}
			}

			$options .= '<input type="' . $args{type} . '" name="' . $args{name} . '"' . $html_attributes . $data_attributes . $checked . ' /><label for="' . $cloned_args->{id} . '">' . $args{options}->{$key} . '</label>';
		}
	}
	elsif (ref $args{options} eq 'ARRAY') {
		foreach my $key (@{$args{options}}) {
			$cloned_args->{id} = $args{name} . '-' . _id($key);
			$cloned_args->{value} = $key;
			my $html_attributes = _html_attribute('', $self->{config}->{'radio-checkbox-html-attribute'}, $cloned_args);

			my $checked = '';

			if (defined $args{value}) {

				if (ref $args{value} eq 'ARRAY') {
					foreach my $element (@{$args{value}}) {
						if ($key eq $element) {
							$checked = ' checked="checked"';
							last;
						}
					}
				}
				elsif ($key eq $args{value}) {
					$checked = ' checked="checked"';
				}
			}

			$options .= '<input type="' . $args{type} . '" name="' . $args{name} . '"' . $html_attributes . $data_attributes . $checked . ' /><label for="' . $cloned_args->{id} . '">' . $key . '</label>';
		}
	}
	else {
		$options = $args{options};
	}

	my $invalid = $args{invalid} ? $self->{config}->{invalid}->(\%args) : '';
	
	my $controlgroup = clone ($args{controlgroup});
	$controlgroup->{fieldset} = 1;
	$controlgroup->{content} ||= '  <legend>' . $self->{config}->{label}->(\%args) .  ':</legend>' . $options . $invalid;

	return $self->controlgroup(%{$controlgroup});
}

sub _header_footer_attribute {
	my ($self, $type, $args) = @_;
	my $attributes = '';

	if (exists $args->{'fixed'}) {
		if ($args->{'fixed'}) {
			$attributes = ' data-position="fixed"';
		}
	}
	elsif ($self->{config}->{$type . '-fixed'}) {
		$attributes = ' data-position="fixed"';
	}

	if (exists $args->{'fullscreen'}) {
		if ($args->{'fullscreen'}) {
			$attributes .= ' data-fullscreen="true"';
		}
	}
	elsif ($self->{config}->{$type . '-fullscreen'}) {
		$attributes .= ' data-fullscreen="true"';
	}

	$attributes = _html_attribute($attributes, $self->{config}->{'header-footer-html-attribute'}, $args);
	$attributes = _data_attribute($attributes, $self->{config}->{'header-footer-data-attribute'}, $args);

	return $attributes;
}

sub _html_attribute {
	my ($attributes, $options, $args) = @_;

	foreach my $option (@{$options}) {
		if (exists $args->{$option}) {
			$attributes .= ' ' . $option . '="' . $args->{$option} . '"';
		}
	}

	return $attributes;
}

sub _data_attribute {
	my ($attributes, $options, $args) = @_;
	foreach my $option (@{$options}) {
		if (exists $args->{'data-' . $option}) {
			$attributes .= ' data-' . $option . '="' . $args->{'data-' . $option} . '"';
		}
		elsif (exists $args->{$option}) {
			$attributes .= ' data-' . $option . '="' . $args->{$option} . '"';
		}
	}
	return $attributes;
}

sub _label {
	my $string = shift;
	$string =~ s/_/ /g;
	$string =~ s/\b(\w)/\u$1/gx;
	return $string;
}

sub _id {
	my $text = shift;
	$text =~ s/&/and/g;
	$text =~ s/\//-/g;
	$text =~ s/[^0-9A-Za-z\-_.:]//g;
	return lc($text);
}

1;

__END__

=head1 NAME

JQuery::Mobile - interface to jQuery Mobile

=head1 SYNOPSIS

  use JQuery::Mobile;

  my $jquery_mobile = JQuery::Mobile->new(config => {'app-title' => 'Hello Mobile World'});

  # create a listview
  my $list = $jquery_mobile->listview(
    anchor => {rel => 'dialog', transition => 'pop'},
    items => [
      {value => 'Quick List', divider => 1},
      {aside => '02/06', count => '6', image => 'http://placehold.it/100x100', title => 'One', href => '#item-link'},
      {aside => '03/07', count => '8', image => 'http://placehold.it/100x100', title => 'Two', href => '#item-link'},
      {aside => '04/08', count => '10', image => 'http://placehold.it/100x100', title => 'Three', href => '#item-link'},
    ],
    filter => 'true',
  );

  # renders a complete HTML page using a "multi-page" template (see reference http://jquerymobile.com/test/docs/pages/page-anatomy.html)
  print $jquery_mobile->pages(
    pages => [
      {
      	id => 'home', 
      	header => {content => '<h1>Home</h1>'}, 
      	content => $list
      },
      {
      	id => 'item-link', 
      	header => {content => '<h1>Item Heading</h1>'}, 
      	content => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit'
      },
    ]
  );

=head1 DESCRIPTION

JQuery::Mobile is an interface to jQuery Mobile. It generates HTML markups, such as navbars, forms, and listviews, that are compatible with jQuery Mobile.

=head1 METHODS

=head2 C<new>

To instantiate a new JQuery::Mobile object:

  my $jquery_mobile = JQuery::Mobile->new();

Here is a list of optional parameters when instantiating a JQuery::Mobile object:

  # default values are shown
  my $jquery_mobile = JQuery::Mobile->new(
     config => {
      'head' => 1, # include <html>, <head>, and <body> tag when rendering a page
      'viewport' => 'width=device-width, initial-scale=1', # default viewport
      'apple-mobile-web-app-capable' => 1, # enable as apple web app
      'apple-touch-icon' => '', # path to apple web app icon image
      'apple-touch-icon-72' => '', # path to apple web app icon image (72x72 pixels)
      'apple-touch-icon-114' => '', # path to apple web app icon image (114x114 pixels)
      'apple-touch-startup-image' => '', # path to apple web app startup image
      'jquery-mobile-css' => 'http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.css',
      'jquery-mobile-js' => 'http://code.jquery.com/mobile/1.3.2/jquery.mobile-1.3.2.min.js',
      'jquery' => 'http://code.jquery.com/jquery-1.9.1.min.js',
      'app-css' => [], # global application CSS files
      'app-js' => [], # global application JS files
      'app-inline-css' => '      span.invalid{color:#F00000;line-height: 1.5;}', # inline CSS code
      'app-inline-js' => '', # inline JS code
      'app-title' => '', # <title> in <head>
     }
  );

The allowed HTML and data-* attributes for each UI component can be customised. By default, HTML attributes are very strict to ensure a clean markup. For data-* attributes, see reference: http://api.jquerymobile.com/data-attribute/.

  # default values are shown
  my $jquery_mobile = JQuery::Mobile->new(
    config => {
      'header-footer-html-attribute' => ['id', 'class'],
      'header-footer-data-attribute' => ['id', 'fullscreen', 'position', 'theme'],
      'navbar-html-attribute' => ['id', 'class'],
      'navbar-data-attribute' => ['disable-page-zoom', 'enhance', 'fullscreen', 'iconpos', 'tap-toggle', 'theme', 'transition', 'update-page-padding', 'visible-on-page-show'],
      'navbar-item-html-attribute' => ['id', 'class', 'target'],
      'navbar-item-data-attribute' => ['ajax', 'icon', 'iconpos', 'iconshadow','prefetch', 'theme'],
      'page-html-attribute' => ['id', 'class'],
      # combine data-attributes for page and dialog
      'page-data-attribute' => ['add-back-btn', 'back-btn-text', 'back-btn-theme', 'close-btn', 'close-btn-text', 'corners', 'dom-cache', 'enhance', 'overlay-theme', 'role', 'shadow','theme', 'title', 'tolerance', 'url'],
      'popup-html-attribute' => ['id', 'class'],
      'popup-data-attribute' => ['corners', 'overlay-theme', 'shadow', 'theme', 'tolerance', 'position-to', 'rel', 'role', 'transition'],
      'listview-html-attribute' => ['id', 'class'],
      'listview-data-attribute' => ['autodividers', 'count-theme', 'divider-theme', 'enhance', 'filter', 'filter-placeholder', 'filter-theme', 'filtertext', 'header-theme', 'inset', 'split-icon', 'split-theme', 'theme'],
      'listview-item-html-attribute' => ['id', 'class'],
      'listview-item-data-attribute' => ['ajax', 'mini', 'rel', 'theme', 'transition'],
      'collapsible-html-attribute' => ['id', 'class'],
      'collapsible-data-attribute' => ['collapsed', 'collapsed-icon', 'content-theme', 'expanded-icon', 'iconpos', 'inset', 'mini', 'theme'],
      'collapsible-set-html-attribute' => ['id', 'class'],
      'collapsible-set-data-attribute' => ['collapsed-icon', 'content-theme', 'expanded-icon', 'iconpos', 'inset', 'mini', 'theme'],
      'controlgroup-html-attribute' => ['id', 'class'],
      'controlgroup-data-attribute' => ['enhance', 'iconpos', 'theme', 'type'],
      'button-html-attribute' => ['id', 'name', 'class', 'maxlength', 'size', 'type', 'value'],
      'button-html-anchor-attribute' => ['id', 'class', 'href', 'target'],
      'button-data-attribute' => ['ajax', 'corners', 'dialog', 'direction', 'dom-cache', 'external', 'icon', 'iconpos', 'iconshadow', 'inline', 'mini', 'position-to', 'prefetch', 'rel', 'role', 'shadow', 'theme', 'transition'],
      'form-html-attribute' => ['id', 'action', 'class', 'enctype', 'method'],
      'form-data-attribute' => ['enhance', 'theme', 'ajax'],
      'input-html-attribute' => ['id', 'class', 'disabled', 'max', 'maxlength', 'min', 'name', 'pattern', 'placeholder', 'readonly', 'required', 'size', 'type', 'value', 'accept', 'capture'],
      'input-data-attribute' => ['clear-btn', 'clear-btn-text', 'corners', 'highlight', 'icon', 'iconpos', 'iconshadow', 'inline', 'mini', 'shadow', 'theme', 'track-theme'],
      'textarea-html-attribute' => ['id', 'name', 'class', 'rows', 'cols', 'readonly', 'disabled', 'title', 'required', 'placeholder', 'title', 'pattern'],
      'textarea-data-attribute' => ['clear-btn', 'clear-btn-text', 'mini', 'theme'],
      'select-html-attribute' => ['id', 'class', 'size', 'maxlength', 'readonly', 'disabled', 'title', 'required', 'placeholder', 'title', 'pattern'],
      'select-data-attribute' => ['icon', 'iconpos', 'inline', 'mini', 'native-menu', 'overlay-theme', 'placeholder', 'theme'],
      'radio-checkbox-html-attribute' => ['id', 'class', 'readonly', 'disabled', 'title', 'required', 'placeholder', 'title', 'pattern', 'value'],
      'radio-checkbox-data-attribute' => ['mini', 'theme']
     }
  );

The C<label> parameter accepts a sub callback to alter how form field labels are being generated:

  my $jquery_mobile = JQuery::Mobile->new(
    config => {
      'label' => sub {
        my $args = shift;
        return '<strong>' . $args->{label} . '*</strong>' if $args->{required};
        return $args->{label};
      },
    }
  );

=head2 C<head>

C<head()> is called by C<page()> and C<pages()> internally to render the HTML header. Parameters via C<new()> controlls the output of C<head()>.

=head2 C<header>

C<header()> generates header toolbars. Text, buttons, or C<navbar()> can be passed to the C<content> parameter.

  print $jquery_mobile->header(
    content => $jquery_mobile->button(href => '#', value => 'Home', icon => 'home', iconpos => 'notext') . '<h1>Main Title</h1>',
  );

prints:

  <div data-role="header">
    <a data-icon="home" data-iconpos="notext" data-role="button" href="#">Home</a>
    <h1>Main Title</h1>
  </div><!-- /header -->

Attributes defined in C<header-footer-html-attribute> and C<header-footer-data-attribute> can be passed to C<header()>, based on the default configuration:

  print $jquery_mobile->header(
    'content' => '<h1>Header Content</h1>',
    'id' => 'home-main-header',
    'class' => 'site-header',
    'data-id' => 'main-header', # use the 'data-*' prefix since 'id' is both a HTML and data atrribute
    'fullscreen' => 'true',
    'position' => 'fixed',
    'theme' => 'e'
  );

=head2 C<footer>

Similar to C<header()>, C<footer()> generates footer toolbars. Attributes defined in C<header-footer-html-attribute> and C<header-footer-data-attribute> can be passed to C<footer()>.

  print $jquery_mobile->footer(
    position => 'fixed',
    content => 'Footer content'
  );

=head2 C<popup>

C<popup()> generates popup container divs. Content can be passed via the C<content> parameter:

  my $popup = $jquery_mobile->popup(id => 'popup', content => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit');

Attributes defined in C<popup-html-attribute> and C<popup-data-attribute> can be passed to C<popup()>.
Please note that as of writing (jQuery Mobile 1.2), according to the jQuery Mobile website, popups "must live within the page wrapper (for now)".

=head2 C<page>

C<page()> generates a container divs. It accepts the following parameters:

=over

=item C<role>

C<role> can be either "page" or "dialog", defaulted to "page".

=item C<head>

C<page()> includes HTML C<head> and C<body> wrapper tags by default. Set C<head> to "0" to disable that:

  print $jquery_mobile->page(head => 0);

=item C<content>

C<content> accepts text string.

=item C<header>

C<header> includes a header toolbars. C<header> accepts a hashref of parameters that gets passed directly to C<header()>.

=item C<footer>

C<footer> includes a footer toolbars. C<footer> accepts a hashref of parameters that gets passed directly to C<footer()>.

=back

For example:

  print $jquery_mobile->page(
    header => {
      content => $jquery_mobile->button(href => '#', value => 'Home', icon => 'home', iconpos => 'notext') . '<h1>Main Title</h1>',
    },
    footer => {
      position => 'fixed',
      content => '<h3>Footer content</h3>'
    },
    content => 'Lorem ipsum dolor sit amet, consectetur adipisicing elit'
  );

=head2 C<pages>

C<pages()> generates a "multi-page" template. It accepts the following parameters:

=over

=item C<head>

C<pages()> includes HTML C<head> and C<body> wrapper tags by default. Set C<head> to "0" to disable that.

=item C<pages>

C<pages> accepts an arrayref of parameters acceptable by C<page()>.

=back

  print $jquery_mobile->pages(
    pages => [
      {id => 'page-1', header => {content => '<h1>Page One Heading</h1>'}, content => 'Cillum dolore eu fugiat nulla pariatur. ' . $jquery_mobile->button(icon => 'arrow-r', value => 'Page 2', href => '#page-2')},
      {id => 'page-2', header => {content => '<h1>Page Two Heading</h1>'}, content => 'Excepteur sint occaecat cupidatat non'},
    ]
  );

=head2 C<form>

C<form()> generates web forms. It accepts attributes defined in C<form-html-attribute> and C<form-data-attribute>. Fields are passed in via the C<fields> arrayref. See form inputs below for reference.
  
  my $form = $jquery_mobile->form(
    title => 'The Form',
    description => 'A description of the form',
    action => '/',
    method => 'get', # defaulted to 'post'
    fields => [
      {name => 'first_name', required => 'required'},
      {name => 'last_name', label => 'Surname', required => 'required'},
      {name => 'email', type => 'email', required => 'required'},
      {name => 'password', type => 'password'},
      {name => 'avatar', type => 'file', accept => 'image/*', capture=> 'camera'},
      {name => 'comment', type => 'textarea'},
      {type => 'radio', name => 'gender', options => ['Male', 'Female']},
      {type => 'checkbox', name => 'country', options => {'AU' => 'Austalia', 'US' => 'United States'}, value => 'AU'},
      {type => 'select', name => 'heard', label => 'How did you hear about us', options => ['Facebook', 'Twitter', 'Google', 'Radio', 'Other']},
      {type => 'rangeslider', name => 'range', mini => 'true', from => {label => 'Range', name => 'from', min => 18, max => 100}, to => {name => 'to', min => 18, max => 100}},
    ],
    controlgroup => {type => 'horizontal'}, # use controlgroup to group the buttons, default to false, accepts "1" or a hashref
    buttons => [
      {value => 'Submit', type => 'submit', icon => 'arrow-r', theme => 'b'},
      {value => 'Cancel', href => '#', icon => 'delete'}
    ],
  );

  print $jquery_mobile->page(content => $form);

Javascript validation can be added to the form using jQuery-Mobilevalidate L<https://github.com/dannyglue/jQuery-Mobilevalidate/>:

  my $jquery_mobile = JQuery::Mobile->new(
    config => {
      'app-title' => 'Hello Mobile World', 
      'app-js' => ['https://raw.github.com/dannyglue/jQuery-Mobilevalidate/master/jquery.mobilevalidate.min.js'],
      'app-inline-js' => '$(document).bind("pageinit", function(){
        $("form").mobilevalidate({novalidate: true});
      });',
    }
  );

  my $form = $jquery_mobile->form(
    title => 'Testing Form Validation',
    action => '/',
    fields => [
      {name => 'email', type => 'email', required => 'required'},
      {name => 'password', type => 'password', required => 'required'},
      {type => 'checkbox', name => 'country', options => {'AU' => 'Austalia', 'US' => 'United States'}, value => 'AU', required => 'required'},
      {type => 'select', name => 'heard', label => 'How did you hear about us', options => ['Facebook', 'Twitter', 'Google', 'Radio', 'Other'], required => 'required'},
    ],
    buttons => [
      {value => 'Submit', type => 'submit', icon => 'arrow-r', theme => 'b'},
    ],
  );

  print $jquery_mobile->pages(
    pages => [
      {id => 'form', content => $form},
      {id => 'errordialog', role => "dialog", header => {content => '<h1>Validating</h1>'}, content => ''},
    ]
  );

=head2 C<listview>

C<listview()> generates listviews. It accepts attributes defined in C<listview-html-attribute> and C<listview-data-attribute>.

  my $list = $jquery_mobile->listview(
    anchor => {rel => 'dialog', transition => 'pop'}, # anchor configuration
    items => [
      {value => 'Quick List', divider => 1},
      {aside => '02/06', count => '6', image => 'http://placehold.it/100x100', title => 'One', href => '#'},
      {aside => '03/07', count => '8', image => 'http://placehold.it/100x100', title => 'Two', href => '#'},
      {aside => '04/08', count => '10', image => 'http://placehold.it/100x100', title => 'Three', href => '#'},
    ],
    inset => 'true',
    filter => 'true',
  );

  print $jquery_mobile->page(content => $list);

=head2 C<table>

C<table()> generates tables. It accepts attributes defined in C<table-html-attribute> and C<table-data-attribute>.

  my $table = $jquery_mobile->table(
    class => 'ui-responsive',
    th => {
      'First Name' => {priority => '1'}, 
      'Last Name' => {priority => '2'}, 
      'Email' => {priority => '3'}, 
      'Gender' => {priority => '4'}, 
    },
    headers => ['First Name', 'Last Name', 'Email', 'Gender'],
    rows => [
      ['John', 'Smith', 'john@work.com', 'Male'],
      ['Ann', 'Smith', 'ann@work.com', 'Female'],
    ],
  );

  print $jquery_mobile->page(content => $table);

=over

=item C<numbered>

C<numbered> can be set to "1", defaulted to false, i.e. HTML C<ul>.

=item C<anchor>

C<anchor> accepts a hashref to control the attributes of the item anchor links. It accepts attributes defined in C<button-html-anchor-attribute> and C<button-data-attribute>.

=item C<split_anchor>

C<split_anchor> accepts a hashref to control the attributes of the item split anchor links (Split button lists). It accepts attributes defined in C<button-html-anchor-attribute> and C<button-data-attribute>.

  my $list = $jquery_mobile->listview(
    anchor => {rel => 'dialog', transition => 'pop'},
    split_anchor => {transition => 'fade', theme => 'e'},
    items => [
      {title => 'One', href => '#link-1', split => '#split-link-1', split_value => 'Split Value One'},
      {title => 'Two', href => '#link-2', split => '#split-link-2', split_value => 'Split Value Two'},
      {title => 'Three', href => '#link-3', split => '#split-link-3', split_value => 'Split Value Three'},
    ]
  );

  print $jquery_mobile->page(content => $list);

=item C<items>

C<items> accepts an arrayref of items. Each item accepts a hashref of C<aside>, C<count>, C<image>, C<title>, C<value> and C<href>.
Alternative, formatted content can be passed in via the C<content> parameter, which takes precedent over the other parameters.


=back

=head2 C<collapsible>

C<collapsible()> generates collapsible blocks. It accepts attributes defined in C<collapsible-html-attribute> and C<collapsible-data-attribute>. Content can be passed via the C<content> parameter:

  my $collapsible = $jquery_mobile->collapsible(
    content => '<h3>Title Heading</h3><p>Excepteur sint occaecat cupidatat non</p>'
  );

  print $jquery_mobile->page(
    content => $collapsible
  );

C<collapsible()> also accepts C<title>, C<active>, and C<listview> as parameters for creating accordion menus via C<collapsible_set()>. See C<collapsible_set()> below.

=head2 C<collapsible_set>

C<collapsible_set()> generates collapsible sets. It accepts attributes defined in C<collapsible-set-html-attribute> and C<collapsible-set-data-attribute>. Collapsible content can be passed via the C<collapsibles> parameter:

  my $collapsible_set = $jquery_mobile->collapsible_set(    
    collapsibles => [
      {content => '<h3>Item Heading One</h3><p>Item One Content</p>'},
      {content => '<h3>Item Heading Two</h3><p>Item Two Content</p>'},
    ]
  );

  print $jquery_mobile->page(
    content => $collapsible_set
  );

C<collapsible_set()> can also create accordion menus when using with C<listview()>:

  my $accordion = $jquery_mobile->collapsible_set(    
    active => {
      option => 'title', # what listview item attribute to check for and set it as active 
      value => 'Menu A Item Two' # open the accordion menu where the listview item has the title: 'Menu A Item Two'
    },
    collapsibles => [
      {
        title => 'Menu A',
        listview => {
          items => [
            {title => 'Menu A Item One', href => '#'},
            {title => 'Menu A Item Two', href => '#'},
          ]
        }
      },
      {
        title => 'Menu B',
        listview => {
          items => [
            {title => 'Menu B Item One', href => '#'},
            {title => 'Menu B Item Two', href => '#'},
          ]
        }
      },
    ]
  );

  print $jquery_mobile->page(
    content => $accordion
  );

=head2 C<navbar>

C<navbar()> generates navbars that are often used in C<header()> and C<footer()>. It accepts attributes defined in C<navbar-html-attribute> and C<navbar-data-attribute>.

  my $navbar = $jquery_mobile->navbar(
    items => [
      {value => 'Item One', href => '#'}, 
      {value => 'Item Two', href => '#', active => 1, persist => 1},
      {value => 'Item Three', href => '#'}
    ]
  );

  print $jquery_mobile->page(
    header => {content => $navbar},
  );

C<items> accepts an arrayref of items (i.e. generates HTML C<li> tags). Navbar item attributes are controlled by C<navbar-item-data-attribute> and C<navbar-item-html-attribute>.
C<active> adds the 'ui-btn-active' class to the item's CSS.
C<persist> adds the 'ui-btn-persist' class to the item's CSS.

=head2 C<button>

C<button()> generates C<anchor> and C<input> buttons. 

  # an anchor button
  print $jquery_mobile->button(
    role => 'button', # could be 'button' or 'none', defaulted to 'button'
    href => 'https://www.google.com',
    mini => 'true',
    value => 'Learn More',
    icon => 'arrow-r',
    iconpos => 'right',
    inline => 'true',
    ajax => 'false',
  );

  # a submit button
  print $jquery_mobile->button(
    type => 'submit',
    value => 'Join Now',
    theme => 'e'
  );

Please note that C<anchor> buttons accepts C<button-html-anchor-attribute> as data-* attributes, whereas C<input> buttons uses C<button-data-attribute>. HTML attributes for both are defined in C<button-html-attribute>.

=head2 C<panel>

C<panel()> generates panel containers. Content can be passed via the C<content> parameter:

  my $panel = $jquery_mobile->panel(
  	content => 'Panel Content'
  );

It accepts attributes defined in C<panel-html-attribute> and C<panel-data-attribute>.

=head2 C<controlgroup>

C<controlgroup()> generates controlgroup containers. Content (usually buttons) can be passed via the C<content> parameter:

  my $controlgroup = $jquery_mobile->controlgroup(
  	mini => 'true',
  	type => 'horizontal',
  	content => '<a href="#" data-role="button">Yes</a><a href="#" data-role="button">No</a>'
  );

It accepts attributes defined in C<controlgroup-html-attribute> and C<controlgroup-data-attribute>. C<form()> uses C<controlgroup()> internally.

=head2 C<input>

C<input()> generates various input elements, such as text, email, password, and file. It accepts attributes defined in C<input-html-attribute> and C<input-data-attribute>. C<form()> uses C<input()> internally.

  print $jquery_mobile->input(
    id => 'logo', # optional element ID. If not defiend, input 'name' will be used as the 'id'
    name => 'avatar', # MUST have a 'name'
    label => 'Member Avatar', # optional 'label' for the input. If not defined, JQuery::Mobile will generate a label based on the input 'name'
    type => 'file', # optional HTML input types, e.g. 'email', 'password', 'file'. Defaulted to 'text'
    accept => 'image/*', # accepts only images (iOS 6+)
    capture => 'camera'  # allow taking new pictures (iOS 6+)
  );

The generated HTML conforms to jQuery Mobile form elements. For instance, inputs are wrapped in a 'fieldcontainer' div.

=head2 C<select>

C<select()> generates select boxes. It accepts attributes defined in C<select-html-attribute> and C<select-data-attribute>.

  print $jquery_mobile->select(
    name => 'into',
    options => ['Movies', 'Music', 'Photography', 'Everything'],
    value => 'Everything'
  );

C<options> can be arrayref or hashref.

=head2 C<checkbox>

C<checkbox()> generates checkboxes. It accepts attributes defined in C<radio-checkbox-html-attribute> and C<radio-checkbox-data-attribute>.

  print $jquery_mobile->checkbox(
    name => 'web_language',
    options => ['PHP', 'Perl', 'Python', 'Ruby']
  );

=head2 C<radio>

C<radio()> generates radio button groups. It accepts the same parameters as C<checkbox()>.

  print $jquery_mobile->radio(
    name => 'country', 
    options => {'AU' => 'Austalia', 'US' => 'United States'}
  );

=head2 C<textarea>

C<textarea()> generates textareas. It accepts attributes defined in C<textarea-html-attribute> and C<textarea-data-attribute>.

  print $jquery_mobile->textarea(
    name => 'comments', 
    rows => '3',
    cols => '50'
  );

=head2 C<rangeslider>

C<rangeslider()> generates rangesliders. It accepts attributes defined in C<rangeslider-html-attribute> and C<rangeslider-data-attribute>.

  print $jquery_mobile->rangeslider(
    type => 'rangeslider', 
    name => 'range', 
    mini => 'true', 
    from => {
      label => 'Range', name => 'from', min => 18, max => 100}, to => {name => 'to', min => 18, max => 100}
  );


=head1 SEE ALSO

L<http://jquerymobile.com>, L<https://github.com/dannyglue/jQuery-Mobilevalidate>

=head1 AUTHOR

Xufeng (Danny) Liang (danny.glue@gmail.com)

=head1 COPYRIGHT & LICENSE

Copyright 2013 Xufeng (Danny) Liang, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut