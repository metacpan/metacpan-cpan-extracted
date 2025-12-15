# NAME

Finance::MIFIR::CONCAT - provides CONCAT code generation out of client data according to MIFIR rules

# SYNOPSYS

    use Finance::MIFIR::CONCAT /mifir_concat/
    print mifir_concat({
        cc          => 'DE',
        date        => '1960-01-01',
        first_name  => 'Jack',
        last_name   => 'Daniels',
    });
