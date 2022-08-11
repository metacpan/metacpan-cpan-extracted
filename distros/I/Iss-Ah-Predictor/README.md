# iss-ah-predictor

Blum et al. [[1](#references)] developed a set of algorithms for the prediction of adult height (AH) in patients with idiopathic short stature (ISS), based on a German-Dutch cohort. The iss-ah-predictor is a convenient Perl implementation of these algorithms.

Depending of the amount of available patient properties, a specific set of parameters is used to calculate AH. The following properties are used in the algorithms:

| property                               | unit         | LOINC code                           |
| -------------------------------------- | ------------ | -------------------------------------|
| chronological age                      | years        | [30525-0](https://loinc.org/30525-0) |
| body height at baseline                | cm           | [3137-7](https://loinc.org/3137-7)   |
| Tanner target height [[2](references)] | cm           |                                      |
| mother height                          | cm           | [83846-6](https://loinc.org/83846-6) |
| father height                          | cm           | [83845-8](https://loinc.org/83845-8) |
| bone age                               | years        | [85151-9](https://loinc.org/85151-9) |
| birth weight                           | kg           | [8339-4](https://loinc.org/8339-4)   |
| sex                                    | male, female | [46098-0](https://loinc.org/46098-0) |

## Installation

```sh
cpan iss-ah-predictor
```

After installing, you can find documentation for this module with the
perldoc command.

```sh
perldoc Iss::Ah::Predictor
```

You can also look for information at:

    Search CPAN
        http://search.cpan.org/dist/iss-ah-predictor/

### Build from Source

```sh
perl Makefile.PL
make
make test
make install
```

## Usage

```perl

```

## References

**[1]** Blum WF, Ranke MB, Keller E, Keller A, Barth S, de Bruin C, Wudy SA, Wit JM. *A Novel Method for Adult Height Prediction in Children With Idiopathic Short Stature Derived From a German-Dutch Cohort.* Journal of the Endocrine Society, Volume 6, Issue 7, July 2022, bvac074. https://doi.org/10.1210/jendso/bvac074

**[2]** Tanner JM, Goldstein H, Whitehouse RH. *Standards for Children's Height at Ages 2-9 Years Allowing for Height of Parents.* Archives of Disease in Childhood, 1970, 45:755-762. https://doi.org/10.1136/adc.45.244.755

## License and Copyright

Copyright (C) 2017-2022 CrescNet, Leipzig University

This program is released under the following license: MIT
