package LaTeX::TikZ::TestX::FromTestY;

use Mouse::Util::TypeConstraints;

coerce 'LaTeX::TikZ::TestX::Autocoerce'
    => from 'LaTeX::TikZ::TestY'
    => via { LaTeX::TikZ::TestX->new(id => int $_->num) };

1;
