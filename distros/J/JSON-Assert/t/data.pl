sub json {
    my $json = <<'EOF';
{ "catalog": {
  "cd": [
    { "barcode": "5-901234-123457",
      "title": "Empire Burlesque",
      "artist": "Bob Dylan",
      "country": "USA",
      "company": "Columbia",
      "price": 10.90,
      "year": 1985,
      "rating": 5
    },
    { "barcode": "9-400097-038275",
      "genre": "Pop",
      "title": "Hide your heart",
      "artist": "Bonnie Tyler",
      "country": "UK",
      "company": "CBS Records",
      "price": 9.90,
      "year": 1988
    },
    { "barcode": "9-414982-021013",
      "genre": "Country",
      "title": "Greatest Hits",
      "artist": "Dolly Parton",
      "country": "USA",
      "company": "RCA",
      "price": 9.90,
      "year": 1982,
      "rating": 4
    }
  ]
}
}
EOF
    return $json;
}

1;
