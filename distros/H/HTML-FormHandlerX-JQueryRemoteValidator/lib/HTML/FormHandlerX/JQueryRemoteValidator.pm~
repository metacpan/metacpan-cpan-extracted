package HTML::FormHandlerX::JQueryRemoteValidator;

use HTML::FormHandler::Moose::Role;
use Method::Signatures::Simple;
use JSON ();


has_field _validation_scripts => (type => 'JavaScript', set_js_code => '_js_code_for_validation_scripts');

has validation_endpoint => (is => 'rw', isa => 'Str', default => '/ajax/formvalidator');

has jquery_validator_link => (is => 'rw', isa => 'Str', default => 'http://ajax.aspnetcdn.com/ajax/jquery.validate/1.14.0/jquery.validate.min.js');

has skip_remote_validation_types  => (is => 'rw', isa => 'ArrayRef', default => sub { [ qw(Submit Hidden noCAPTCHA Display JSON JavaScript) ] });

has skip_all_remote_validation => (is => 'rw', isa => 'Bool', default => 0);

method _js_code_for_validation_scripts () {
    my $spec_data = $self->_data_for_validation_spec;
    my $spec = JSON->new->utf8
                        ->allow_nonref
                        ->pretty(1)
                #        ->relaxed(undef)
                #        ->canonical(undef)
                        ->encode($spec_data)
                         || '';

    my $form_name = $self->name;
    $spec =~ s/"${form_name}_data_collector"/${form_name}_data_collector/g;
    $spec =~ s/\n$//;
    $spec = "\n  var ${form_name}_validation_spec = $spec;\n";
    return $self->_data_collector_script . $spec . $self->_run_validator_script;
}

method _data_for_validation_spec () {
    my $js_profile = { rules => {}, messages => {} };

    foreach my $f (@{$self->fields}) {
        next if $self->_skip_remote_validation($f);       # don't build rules for these fields
        if ($f->isa('HTML::FormHandler::Field::Repeatable')) { # also 'Compound' as well but I don't have one of these lying around just yet
            foreach my $subf (sort {$a->name cmp $b->name} map {$_->fields} $f->fields) {
                $js_profile->{rules}->{$subf->id}->{remote} = $self->_build_remote_rule($subf);
            }
        }
        else {
            $js_profile->{rules}->{$f->id}->{remote} = $self->_build_remote_rule($f);
        }
    }

    return $js_profile;
}

method _build_remote_rule ($field) {
    my $remote_rule = {
        url => sprintf("%s/%s/%s", $self->validation_endpoint, $self->name, $field->id),
        type => 'POST',
        data => $self->name . "_data_collector",
        };

    return $remote_rule;
}

method _data_collector_script () {
    my @func;
    foreach my $f (sort {$a->name cmp $b->name} $self->fields) { # the sort is for consistent output in tests
        next if $self->_skip_data_collection($f);
        if ($f->isa('HTML::FormHandler::Field::Repeatable')) { # also 'Compound' as well but I don't have one of these lying around just yet
            foreach my $subf (sort {$a->name cmp $b->name} map {$_->fields} $f->fields) {
                push @func, sprintf "    \"%s\": function () { return \$(\"#%s\").val() }",
                    $subf->id, _escape_dots($subf->id);
            }
        }
        else {
            push @func, sprintf "    \"%s\": function () { return \$(\"#%s\").val() }",
                $f->id, _escape_dots($f->id);
        }
    }

    my $form_name = $self->name;
    return "  var ${form_name}_data_collector = {\n" . join(",\n", @func) . "\n  };\n";
}

sub _escape_dots {
    my $str = shift;
    $str =~ s/\./\\\\./g;
    return $str;
}

method _skip_remote_validation ($field) {
    return 1 if $self->skip_all_remote_validation;
    my %skip_type  = map {$_=>1} @{$self->skip_remote_validation_types};
    return 1 if $field->get_tag('no_remote_validate');
    return 1 if $skip_type{$field->type};
    return 0;
}

method _skip_data_collection ($field) {
    return 0 if $field->type eq 'Hidden'; # collect, but don't validate, hidden fields
    return $self->_skip_remote_validation($field);
}

method _run_validator_script () {
    my $form_name = $self->name;
    my $link = $self->jquery_validator_link;

    my $opts = join ",\n          ",
                    map { sprintf "%s: %s", $_, $self->jquery_validator_opts->{$_} }
                    keys %{$self->jquery_validator_opts};

    $opts = "\n$opts," if $opts;

    my $script = <<SCRIPT;

  \$(document).ready(function() {
    \$.getScript("$link", function () {
      if (typeof ${form_name}_validation_spec !== 'undefined') {
        \$('form#$form_name').validate({$opts
          rules: ${form_name}_validation_spec.rules,
          submitHandler: function(form) { form.submit(); }
        });
      }
    });
  });
SCRIPT

    return $script;
}

# http://jqueryvalidation.org/validate/     - start reading with the summary at the *end* of the page
has 'jquery_validator_opts' => (is => 'rw', isa => 'HashRef[Str]', required => 0, default => sub {{}});

=head1 SYNOPSIS

    package MyApp::Form::Foo;
    use HTML::FormHandler::Moose;

    with 'HTML::FormHandlerX::JQueryRemoteValidator';

    ...

    # You need to provide a form validation script at /ajax/formvalidator
    # In Poet/Mason, something like this in /ajax/formvalidator.mp -

    route ':form_name/:field_name';

    method handle () {
        my $form = $.form($.form_name);
        $form->process(params => $.args, no_update => 1);

        my $err = join ' ', @{$form->field($.field_name)->errors};
        my $result = $err || 'true';

        $m->print(JSON->new->allow_nonref->encode($result));
    }


=cut


=head1 CONFIGURATION AND SETUP

The purpose of this package is to build a set of JQuery scripts and inject them
into your forms. The scripts send user input to your server where you must
provide an endpoint that can validate the fields. Since you already have an
HTML::FormHandler form, you can use that.

The package uses the remote validation feature of the JQuery Validator
framework. This also takes care of updating your form to notify the user of
errors and successes while they fill in the form. You will most likely want
to customise that behaviour for your own situation. An example is given below.

=head2 What you will need

=over 4

=item JQuery

Load the JQuery library somewhere on your page.

=item JQuery validator

See the C<jquery_validator_link> attribute.

=item Server-side validation endpoint

See the C<validation_endpoint> attribute.

=item Some JS fragments to update the form



=item CSS to prettify it all

=back

=head2 An example using the Bootstrap 3 framework

=head3 Markup

    <form ...>

    <div class="form-group form-group-sm">
        <label class="col-xs-3 control-label" for="AddressForm.name"></label>
        <div class="col-xs-6">
            <input type="text" name="AddressForm.name" id="AddressForm.name"
                class="form-control" value="" />
        </div>
        <label for="AddressForm.name" id="AddressForm.name-error"
            class="has-error control-label col-xs-3">
        </label>
    </div>

    <div class="form-group form-group-sm">
        <label class="col-xs-3 control-label" for="AddressForm.address"></label>
        <div class="col-xs-6">
            <input type="text" name="AddressForm.address" id="AddressForm.address"
                class="form-control" value="" />
        </div>
        <label for="AddressForm.address" id="AddressForm.address-error"
            class="has-error control-label col-xs-3">
        </label>
    </div>

    ...

    </form>


=head3 CSS

Most of the classes on the form come from Twitter Bootstrap 3. In this example,
JQuery validator targets error messages to the second <label> on each
form-control. This is the default behaviour but can be changed.

The default setup will display and remove messages as the user progresses
through the form. JQuery Validator offers lots of options. You can read about
them at L<http://jqueryvalidation.org/validate/>. You should start by reading
the few sentences at the very bottom of that page.

Some useful additional styling to get started:

    label.valid {
      width: 24px;
      height: 24px;
      background: url(/static/images/valid.png) center center no-repeat;
      display: inline-block;
      text-indent: -9999px;
    }

    label.error {
      font-weight: normal;
      color: red;
      padding: 2px 8px;
      margin-top: 2px;
    }

=head3 JavaScript

You can provide extra JavaScript functions to control the behaviour of the error
and success messages in the C<jqr_validate_options> attribute:

    my $jqr_validate_options = {
        highlight => q/function(element, errorClass, validClass) {
                $(element).closest('.form-group').addClass(errorClass).removeClass(validClass);
                $(element).closest('.form-group').find("label").removeClass("valid");
            }/,
        unhighlight => q/function(element, errorClass, validClass) {
                $(element).closest('.form-group').removeClass(errorClass);
            }/,
        success => q/function(errorLabel, element) {
                $(element).closest('.form-group').addClass("has-success");
                errorLabel.addClass("valid");
            }/,
        errorClass => '"has-error"',
        validClass => '"has-success"',
        errorPlacement => q/function(errorLabel, element) {
                errorLabel.appendTo( element.parent("div").parent("div") );
            }/,
    };

    has '+jqr_validate_options' => (default => sub {$jqr_validate_options});

=head2 Class (form) attributes

=head3 C<validation_endpoint>

Default: /ajax/formvalidator

The form data will be POSTed to C<[validation_endpoint]/[form_name]/[field_name]>.

Note that *all* fields are submitted, not just the field being validated.

You must write the code to handle this submission. The response should be a JSON
string, either C<true> if the field passed its tests, or a message describing
the error. The message will be displayed on the form.

The synopsis has an example for Poet/Mason.

=head3 C<jquery_validator_link>

Default: http://ajax.aspnetcdn.com/ajax/jquery.validate/1.14.0/jquery.validate.min.js

You can leave this as-is, or if you prefer, you can put the file on your own
server and modify this setting to point to it.

=head3 C<jquery_validator_opts>

Default: {}

A HashRef, keys being the keys of the C<validate> JQuery validator call documented
at L<http://jqueryvalidation.org/validate/>, with values being JavaScript functions
etc. as described there.

=head3 C<skip_remote_validation_types>

Default: C<[ qw(Submit Hidden noCAPTCHA Display JSON JavaScript) ]>

A list of field types that should not be included in the validation calls.

=head3 C<skip_all_remote_validation>

Boolean, default 0.

A flag to turn off remote validation altogether, perhaps useful during form development.


=head2 Field attributes

=head3 Tag C<no_remote_validate> [C<Bool>]

Default: not set

Set this tag to a true value on fields that should not be remotely validated:

    has_field 'foo' => (tags => {no_remote_validate => 1}, ... );


=head1 See also

=over 4

=item L<http://www.catalystframework.org/calendar/2012/23>

=item L<http://alittlecode.com/wp-content/uploads/jQuery-Validate-Demo/index.html>

=item L<http://jqueryvalidation.org>

=back

=cut


=head1 ACKNOWLEDGEMENTS

This started out as a modification of Aaron Trevana's
HTML::FormHandlerX::Form::JQueryValidator

=cut

1; # End of HTML::FormHandlerX::JQueryRemoteValidator
