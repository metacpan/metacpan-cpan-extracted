# FASTX-Abi

[![Dzil Test](https://github.com/telatin/FASTX-Abi/actions/workflows/cpan.yaml/badge.svg)](https://github.com/telatin/FASTX-Abi/actions/workflows/cpan.yaml)

OOP Perl module to convert Sanger trace files (.ab1) to FASTQ sequences. Ambiguities (hetero bases) are managed.

Homepage: [FASTX::Abi (MetaCPAN)](https://metacpan.com/pod/FASTX::Abi)

![alt text](https://raw.githubusercontent.com/telatin/FASTX-Abi/master/img/chromatogram.png)

The picture shows a trace file (chromatogram, in abi/ab1 format) with a SNP detected and the typical quality degradation at the end.

## Installing

Via cpanminus:
```
# Install cpanminus if you don't have it:
curl -L https://cpanmin.us | perl - --sudo App::cpanminus

# Install FASTX::Abi
cpanm FASTX::Abi
```

Via [Miniconda](https://docs.conda.io/en/latest/miniconda.html):
```

# Install FASTX::Abi
conda install -y -c bioconda perl-fastx-abi
```
