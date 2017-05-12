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

public class PipelineCoreference extends PipelineItem {
    private int fromSentence;
    private int toSentence;
    private int fromHead;
    private int toHead;
    private PipelineToken fromToken;
    private PipelineToken toToken;

    public int getSourceSentence()        { return fromSentence; }
    public int getTargetSentence()        { return toSentence; }
    public int getSourceHead()            { return fromHead; }
    public int getTargetHead()            { return toHead; }
    public PipelineToken getSourceToken() { return fromToken; }
    public PipelineToken getTargetToken() { return toToken;   }

    public PipelineCoreference(
            int fromSentence, int toSentence, int fromHead, int toHead,
            PipelineToken fromToken, PipelineToken toToken
    ) {
         this.fromSentence = fromSentence;
         this.toSentence   = toSentence;
         this.fromHead     = fromHead;
         this.toHead       = toHead;
         this.fromToken    = fromToken;
         this.toToken      = toToken;
         //this.setIDFromString(fromToken.getIDString() + toToken.getIDString());
    }

    public boolean equals(PipelineCoreference b) {
         if((
              fromToken.identicalTo(b.fromToken)
                         &&
              toToken.identicalTo(b.toToken)
         ) || (
              fromToken.identicalTo(b.toToken)
                         &&
              toToken.identicalTo(b.fromToken)
         ))
              return true;
         else
              return false;
    }

    public String toCompactString() {
         return fromToken.getWord() + "/" + fromSentence + ":" + fromHead + " <=> "
              + toToken.getWord()   + "/" + toSentence   + ":" + toHead;
    }

    @Override public String toString() {
         return fromToken.toCompactString() + " [" + fromSentence + "," + fromHead + "] <=> " +
                toToken.toCompactString()   + " [" + toSentence   + "," + toHead   + "]";
    }
}
