#!/usr/bin/env python3
dna_sequence = ""
protein_sequence = ""
input_sequence = open('protein.txt', 'r')
protein_sequence = input_sequence.read().strip()
print ("Protein Sequence:     ", protein_sequence)

# codon table
code = {
    'A': 'GCT',
    'C': 'TGT',
    'D': 'GAT',
    'E': 'GAA',
    'F': 'TTT',
    'G': 'GGT',
    'I': 'ATT',
    'H': 'CAT',
    'K': 'AAA',
    'L': 'TTA',
    'M': 'ATN',
    'N': 'AAT',
    'P': 'CCT',
    'Q': 'CAA',
    'R': 'CGT',
    'S': 'TCT',
    'T': 'ACT',
    'V': 'GTT',
    'W': 'TGG',
    'Y': 'TAT',
    '*': 'TAA'
}

for i in range(0, len(protein_sequence)):
    print(protein_sequence[i])
    #dna_sequence = dna_sequence + code[protein_sequence[i]]
print ("DNA Sequence:         ", dna_sequence)
