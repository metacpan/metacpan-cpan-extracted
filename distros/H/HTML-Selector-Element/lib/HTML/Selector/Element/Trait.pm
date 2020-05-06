# As both HTML::Selector::Element and HTML::Selector::Element::Trait always must be loaded together,
# all source code is in that other file. in order to avoid problems of modules mutually requiring each other.
# This file only exists so you can call `use HTML::Selector::Element::Trait @FUNCTIONS_YOU_WANT;`without any issues.

require HTML::Selector::Element;

1;
