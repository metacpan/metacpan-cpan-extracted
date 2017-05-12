/*
 * Lingua::StanfordCoreNLP
 * Copyright © 2011-2013 Kalle Räisänen.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see L<http://www.gnu.org/licenses/>.
 */
package be.fivebyfive.lingua.stanfordcorenlp;

public class PipelineToken extends PipelineItem {
	private String word;
	private String posTag;
	private String nerTag;
	private String lemma;

	public String getWord()   { return word; }
	public String getPOSTag() { return posTag; }
	public String getNERTag() { return nerTag; }
	public String getLemma()  { return lemma; }

	public PipelineToken(String word, String posTag, String nerTag, String lemma) {
		this.word   = word;
		this.posTag = posTag;
		this.nerTag = nerTag;
		this.lemma  = lemma;
	}

	@Override public String toString() {
		return word + "/" + lemma + "/" + posTag + "/" + nerTag;
	}

	public String toCompactString() { return toCompactString(false); }

	public String toCompactString(boolean lemmaize) {
		return (lemmaize ? word : lemma) + "/" + posTag;
	}
}
